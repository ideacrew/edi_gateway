# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'securerandom'

module UserFees
  module GdbTransactions
    # Resolve whether passed transaction message is an enrollment addition
    #
    class CheckAdditionTransaction
      include Dry::Monads[:result, :do, :try]
      include EventSource::Command

      # @param [Hash] params the parameters to resolve message type
      # @option params [Hash] :message EDI Database transaction (required)
      # @return [Dry::Monads::Success] message is a addition
      # @return [Dry::Monads::Failure] message is not a addition
      def call(params)
        message = yield validate(params)
        events = yield inspect_transaction(message)
        published_events = yield publish_events(events)

        Success(published_events)
      end

      private

      def validate(message)
        return Success(message) if message.is_a? Hash
        Failure('hash expected')
      end

      def inspect_transaction(message)
        customer_new_state = (message[:customer])
        customer_state = fetch_customer(customer_new_state)

        return Success([detect_new_customer(customer_state, customer_new_state)]) unless customer_state.present?

        policy_events = detect_new_policies(customer_state, customer_new_state)
        tax_household_events = detect_new_tax_households(customer_state, customer_new_state)
        _enrolled_member_events = detect_new_enrollment_members(customer_state, customer_new_state)

        Success([policy_events, tax_household_events].compact)
        # Success([policy_events]) #, tax_household_events, enrolled_member_events].compact)
      rescue StandardError => e
        Failure("error parsing transaction:\n    #{customer_new_state}\n    #{e}")
        # Failure("error parsing transaction:\n    #{customer_new_state}\n    #{e.backtrace}")
      end

      def publish_events(events)
        Success(events.each { |event| event.success.publish })
      rescue StandardError => e
        Failure("error publshing events:\n    #{e}\n    events: #{events}\n    #{e}")
      end

      def fetch_customer(customer)
        ::UserFees::Customer.find_by(hbx_id: customer[:hbx_id]) || {}
      end

      # initial enrollment added
      def detect_new_customer(customer_state, customer_new_state)
        build_event('initial_enrollment_added', {}, customer_state, customer_new_state) if customer_state.empty?
      end

      # policies added
      def detect_new_policies(customer_state, customer_new_state)
        policies = customer_state.insurance_coverage.policies || []
        new_policies = customer_new_state.dig(:insurance_coverage, :policies) || []

        new_policy_set =
          new_policies.reduce([]) do |list, np|
            list << np if policies.none? { |policy| policy.exchange_assigned_id == np.fetch(:exchange_assigned_id) }
            list
          end

        return nil if new_policy_set.empty?
        build_event('policies_added', new_policy_set, customer_state, customer_new_state) || []
      end

      # tax households added
      def detect_new_tax_households(customer_state, customer_new_state)
        tax_hhs = customer_state.insurance_coverage.tax_households || []
        new_tax_hhs = customer_new_state.dig(:insurance_coverage, :tax_households) || []

        new_tax_household_set =
          new_tax_hhs.reduce([]) do |list, nthh|
            list << nthh if tax_hhs.none? { |tax_hh| tax_hh.exchange_assigned_id == nthh.fetch(:exchange_assigned_id) }
            list
          end

        return nil if new_tax_household_set.empty?
        build_event('tax_households_added', new_tax_household_set, customer_state, customer_new_state) || []
      end

      # enrollment_members added
      def detect_new_enrollment_members(customer_state, customer_new_state)
        []
        # tax_hhs = customer_state.dig(:insurance_coverage, :policies) || []
        # new_tax_hhs = customer_new_state.dig(:insurance_coverage, :policies) || []
        # new_tax_household_set =
        #   new_tax_hhs.reduce([]) do |list, new_tax_hh|
        #     if tax_hhs.none? { |tax_hh| tax_hh[:exchange_assigned_id] == new_tax_hh[:exchange_assigned_id] }
        #       list << new_thh
        #     end
        #   end
        # build_event('enrollment_members_added', customer, new_tax_household_set)
      end

      def build_event(event_name, change_set, customer_state, customer_new_state)
        event_namespace = 'events.user_fees.enrollment_adds'
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
