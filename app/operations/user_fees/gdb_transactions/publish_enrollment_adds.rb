# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'securerandom'

module UserFees
  module GdbTransactions
    # Resolve whether passed transaction message is an enrollment addition
    #
    class PublishEnrollmentAdds
      include Dry::Monads[:result, :do, :try]
      include EventSource::Command

      # @param [Hash] params the parameters to resolve message type
      # @option params [Hash] :message EDI Database transaction (required)
      # @return [Dry::Monads::Success] message is a addition
      # @return [Dry::Monads::Failure] message is not a addition
      def call(params)
        params = yield validate(params)
        events = yield inspect_transaction(params)
        published_events = yield publish_events(events)

        Success(published_events)
      end

      private

      def validate(message)
        AcaEntities::Ledger::Contracts::GdbTransactionContract.new.call(message)
      end

      def inspect_transaction(message)
        customer_new_state = (message[:customer])
        customer_state = fetch_customer(customer_new_state)

        return Success([detect_new_customer(customer_state, customer_new_state)]) unless customer_state.present?
        policy_events = detect_new_policies(customer_state, customer_new_state)
        tax_household_events = detect_new_tax_households(customer_state, customer_new_state)
        enrolled_member_events = nil #detect_new_enrollment_members(customer_state, customer_new_state)

        Success([policy_events, tax_household_events, enrolled_member_events].compact)
      rescue StandardError => e
        Failure[:transaction_parse_error, params: customer_new_state, error: e.to_s, backtrace: e.backtrace]
      end

      def publish_events(events)
        Success(events.each { |event| event.success.publish })
      rescue StandardError => e
        Failure[:event_publish_error, params: customer_new_state, error: e.to_s, backtrace: e.backtrace]
      end

      def fetch_customer(customer)
        ::UserFees::Customer.find_by(hbx_id: customer[:hbx_id]).to_h #|| {}
      end

      # Detect initial enrollment added
      def detect_new_customer(customer_state, customer_new_state)
        build_event('initial_enrollment_added', {}, customer_state, customer_new_state) if customer_state.empty?
      end

      # Detect if customer_new_state has added tax_households compared to customer_state
      # @param [Hash] :customer_state existing customer attributes from persisted record
      # @param [Hash] :customer_new_state new customer attributes from the incoming transaction
      # @return [Dry::Monads::Result::Success, Array<Events::UserFees::EnrollmentAdds::TaxHouseholdsAdded>] if new tax_housholeds are detected
      # @return [Dry::Monads::Result::Success, nil] if no new tax_households are detected
      # @return [Dry::Monads::Result::Failure, Hash] if an error is encountered
      def detect_new_tax_households(customer_state, customer_new_state)
        tax_hhs = customer_state.dig(:insurance_coverage, :tax_households) || []
        new_tax_hhs = customer_new_state.dig(:insurance_coverage, :tax_households) || []
        return if tax_hhs == new_tax_hhs

        new_tax_household_set =
          new_tax_hhs.reduce([]) do |list, nthh|
            list << nthh if tax_hhs.none? { |tax_hh| tax_hh.exchange_assigned_id == nthh.fetch(:exchange_assigned_id) }
            list
          end

        return nil if new_tax_household_set.empty?
        build_event('tax_households_added', new_tax_household_set, customer_state, customer_new_state) || []
      end

      # Detect policies added
      def detect_new_policies(customer_state, customer_new_state)
        policies = customer_state.dig(:insurance_coverage, :policies) || []
        new_policies = customer_new_state.dig(:insurance_coverage, :policies) || []
        return if policies == new_policies

        new_policy_set =
          new_policies.reduce([]) do |list, np|
            list << np if policies.none? { |policy| policy[:exchange_assigned_id] == np.fetch(:exchange_assigned_id) }
            list
          end

        return nil if new_policy_set.empty?
        build_event('policies_added', new_policy_set, customer_state, customer_new_state) || []
      end

      # Detect enrollment_members added
      def detect_new_enrollment_members(customer_state, customer_new_state)
        enrolled_members = enrolled_members_for_insurance_coverage(customer_state[:insurance_coverage])
        new_enrolled_members = enrolled_members_for_insurance_coverage(customer_new_state[:insurance_coverage])
        return if enrolled_members == new_enrolled_members

        new_enrolled_member_set = diff_enrolled_members(enrolled_members, new_enrolled_members)

        return nil if new_enrolled_member_set.empty?
        build_event('enrolled_members_added', new_enrolled_member_set, customer_state, customer_new_state) || []
      end

      def diff_enrolled_members(base_set, compare_set)
        base_set - compare_set
        # new_enrolled_members.reduce([]) do |list, nm|
        #   list << nm if enrolled_members.none? { |em| em.dig(:member, :hbx_id) == nm.dig(:member, :hbx_id) }
        #   list
        # end
      end

      def enrolled_members_for_insurance_coverage(coverage)
        coverage[:policies].reduce([]) do |policy_enrolled_members, policy|
          pol_members =
            policy[:marketplace_segments].reduce([]) do |mkt_enrolled_members, marketplace_segment|
              mkt_enrolled_members += marketplace_segment[:enrolled_members]
              mkt_enrolled_members
            end
          policy_enrolled_members += pol_members
          policy_enrolled_members
        end
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
