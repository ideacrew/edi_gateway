# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'securerandom'

module EdiDatabase
  module Transactions
    # Inspect a GlueDB enrollment transaction comparing it against the
    # existing state to determine whether it indicates enrollment terminations.
    # If so, publish a corresponding enrollment add event
    class PublishEnrollmentTerminations
      send(:include, Dry::Monads[:result, :do])
      include EventSource::Command

      # @param [AcaEntities::Ledger::GdbTransaction] params a GlueDB enrollment transaction
      # @return [Dry::Monads::Success, Array<Events::UserFees::EnrollmentTerminations::EnrollmentTerminated>] if transaction is an
      #   enrollment termination
      # @return [Dry::Monads::Success, Array<Events::UserFees::EnrollmentTerminations::PoliciesTerminated>] if transaction includes
      #   one or more policy terminations
      # @return [Dry::Monads::Success, Array<Events::UserFees::EnrollmentTerminations::TaxHouseholdsTerminated>] if transaction
      #   includes one or more tax household terminations
      # @return [Dry::Monads::Failure] unable to process GdbTransaction
      def call(params)
        params = yield validate(params)
        events = yield inspect_transaction(params)
        published_events = yield publish_events(events)

        Success(published_events)
      end

      private

      # Schema-verify the integrity of the passed parameters
      # @param [Hash] params a GlueDB enrollment transaction
      # @return [Dry::Validation::Result]
      def validate(params)
        AcaEntities::Ledger::Contracts::GdbTransactionContract.new.call(params)
      end

      def inspect_transaction(params)
        customer_new_state = (params[:customer])
        customer_state = fetch_customer(customer_new_state)

        customer_termed_event = detect_termed_enrollment(customer_state, customer_new_state)
        return customer_termed_event if customer_termed_event.present?

        policy_events = detect_termed_policies(customer_state, customer_new_state)
        tax_household_events = detect_termed_tax_households(customer_state, customer_new_state)

        Success([policy_events, tax_household_events].compact)
      rescue StandardError => e
        Failure[:transaction_parse_error, params: customer_new_state, error: e.to_s, backtrace: e.backtrace]
      end

      def fetch_customer(customer)
        ::UserFees::Customer.find_by(hbx_id: customer[:hbx_id]).to_entity.to_h
      end

      # Compare existing with new customer states and detect terminated enrollment.
      #
      # @param [AcaEntities::Ledger::Customer] customer_state existing customer attributes
      # @param [AcaEntities::Ledger::Customer] customer_new_state new customer attributes
      #
      # @return [Dry::Monads::Result::Success, Array<Events::UserFees::EnrollmentTerminations::EnrollmentTerminated>] if a terminated
      #   enrollments is detected
      # @return [Dry::Monads::Result::Success, nil] if terminated enrollment isn't detected
      # @return [Dry::Monads::Result::Failure, Hash] if an error is encountered
      def detect_termed_enrollment(customer_state, customer_new_state)
        coverage_state_is_active = customer_state.dig(:insurance_coverage, :is_active)
        new_coverage_state_is_active = customer_new_state.dig(:insurance_coverage, :is_active)
        return unless coverage_state_is_active && !new_coverage_state_is_active

        build_event('enrollment_terminated', customer_new_state, customer_state, customer_new_state)
      end

      # Compare existing with new customer states and detect terminated tax_households
      #
      # @param [AcaEntities::Ledger::Customer] customer_state existing customer attributes
      # @param [AcaEntities::Ledger::Customer] customer_new_state new customer attributes
      #
      # @return [Dry::Monads::Result::Success, Array<Events::UserFees::EnrollmentTerminations::TaxHouseholdsAdded>] if terminated
      #   tax_households are detected
      # @return [Dry::Monads::Result::Success, nil] if no new tax_households are detected
      # @return [Dry::Monads::Result::Failure, Hash] if an error is encountered
      def detect_termed_tax_households(customer_state, customer_new_state)
        tax_hhs = customer_state.dig(:insurance_coverage, :tax_households)
        new_tax_hhs = customer_new_state.dig(:insurance_coverage, :tax_households)
        return nil if tax_hhs.nil? || tax_hhs.empty? || tax_hhs == new_tax_hhs

        termed_tax_household_set =
          new_tax_hhs.reduce([]) do |list, nthh|
            list << nthh unless tax_hhs.include? nthh
            list
          end

        return nil if termed_tax_household_set.empty?
        build_event('tax_households_terminated', termed_tax_household_set, customer_state, customer_new_state)
      end

      # Compare existing with new customer states and detect terminated policies
      #
      # @param [AcaEntities::Ledger::Customer] customer_state existing customer attributes
      # @param [AcaEntities::Ledger::Customer] customer_new_state new customer attributes
      #
      # @return [Dry::Monads::Result::Success, Array<Events::UserFees::EnrollmentTerminations::PoliciesTerminated>] if terminated
      #   policies are detected
      # @return [Dry::Monads::Result::Success, nil] if no terminated policies are detected
      # @return [Dry::Monads::Result::Failure, Hash] if an error is encountered
      def detect_termed_policies(customer_state, customer_new_state)
        policies = customer_state.dig(:insurance_coverage, :policies)
        new_policies = customer_new_state.dig(:insurance_coverage, :policies)
        return nil if policies == new_policies

        termed_policy_set =
          new_policies.reduce([]) do |list, np|
            list << np unless policies.include? np
            list
          end

        return nil if termed_policy_set.empty?
        build_event('policies_terminated', termed_policy_set, customer_state, customer_new_state)
      end

      def publish_events(*events)
        Success(events.flatten.each { |event| event.respond_to?(:success) ? event.success.publish : event.publish })
      rescue StandardError => e
        Failure[:event_publish_error, events: events, error: e.to_s, backtrace: e.backtrace]
      end

      def build_event(event_name, change_set, customer_state, customer_new_state)
        event_namespace = 'events.user_fees.enrollment_terminations'
        full_event_name = [event_namespace, event_name].join('.')
        meta = build_meta_content(change_set, customer_new_state)
        attributes = {
          meta: meta,
          old_state: {
            customer: customer_state
          },
          new_state: {
            customer: customer_new_state
          }
        }
        event(full_event_name, attributes: attributes)
      end

      def build_meta_content(change_set, customer_new_state)
        correlation_id = SecureRandom.uuid
        time = DateTime.now
        {
          correlation_id: correlation_id,
          time: time,
          customer_hbx_id: customer_new_state[:hbx_id],
          change_set: change_set
        }
      end
    end
  end
end
