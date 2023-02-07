# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'securerandom'

module EdiDatabase
  module Transactions
    # Inspect a GlueDB enrollment transaction comparing it against the
    # existing state to determine whether it indicates enrollment
    # change activities. If so, publish a corresponding enrollment change event
    class PublishEnrollmentChanges
      send(:include, Dry::Monads[:result, :do])
      include EventSource::Command

      # @param [AcaEntities::Ledger::GdbTransaction] params a GlueDB enrollment transaction
      # @return [Dry::Monads::Success, Array<Events::UserFees::EnrollmentAdds::InitialEnrollmentAdded>] if transaction
      #   is an initial enrollment
      # @return [Dry::Monads::Success, Array<Events::UserFees::EnrollmentAdds::PoliciesAdded>] if transaction
      #   includes one or more policy adds
      # @return [Dry::Monads::Success, Array<Events::UserFees::EnrollmentAdds::TaxHouseholdsAdded>] if transaction
      #   includes one or more tax household adds
      # @return [Dry::Monads::Success, Array<Events::UserFees::EnrollmentAdds::EnrolledMembersAdded>] if transaction
      #   includes one or more enrollment member adds
      # @return [Dry::Monads::Success, Array<Events::UserFees::EnrolledMembersAdded] if transaction is a member add
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

        policy_events = detect_new_policies(customer_state, customer_new_state)
        tax_household_events = detect_new_tax_households(customer_state, customer_new_state)
        enrolled_member_events = detect_new_enrollment_members(customer_state, customer_new_state)

        Success([policy_events, tax_household_events, enrolled_member_events].compact)
      rescue StandardError => e
        Failure[:transaction_parse_error, params: customer_new_state, error: e.to_s, backtrace: e.backtrace]
      end

      def fetch_customer(customer)
        ::UserFees::Customer.find_by(hbx_id: customer[:hbx_id]).to_h
      end

      def publish_events(events)
        Success(events.each { |event| event.success.publish })
      rescue StandardError => e
        Failure[:event_publish_error, params: customer_new_state, error: e.to_s, backtrace: e.backtrace]
      end

      # Compare existing with new customer states and detect added tax_households
      #
      # @param [AcaEntities::Ledger::Customer] customer_state existing customer attributes
      # @param [AcaEntities::Ledger::Customer] customer_new_state new customer attributes
      #
      # @return [Dry::Monads::Result::Success, Array<Events::UserFees::EnrollmentAdds::TaxHouseholdsAdded>] if new
      #   tax_housholeds are detected
      # @return [Dry::Monads::Result::Success, nil] if no new tax_households are detected
      # @return [Dry::Monads::Result::Failure, Hash] if an error is encountered
      def detect_new_tax_households(customer_state, customer_new_state)
        tax_hhs = customer_state.dig(:insurance_coverage, :tax_households) || []
        new_tax_hhs = customer_new_state.dig(:insurance_coverage, :tax_households) || []
        return if tax_hhs == new_tax_hhs

        new_tax_household_set =
          new_tax_hhs.each_with_object([]) do |nthh, list|
            list << nthh if tax_hhs.none? { |tax_hh| tax_hh.exchange_assigned_id == nthh.fetch(:exchange_assigned_id) }
          end

        return nil if new_tax_household_set.empty?

        build_event('tax_households_added', new_tax_household_set, customer_state, customer_new_state) || []
      end

      # Compare existing with new customer states and detect added enrollment_members
      #
      # @param [AcaEntities::Ledger::Customer] customer_state existing customer attributes
      # @param [AcaEntities::Ledger::Customer] customer_new_state new customer attributes
      #
      # @return [Dry::Monads::Result::Success, Array<Events::UserFees::EnrollmentAdds::EnrollmentMembersAdded>] if new
      #   enrollment_members are detected
      # @return [Dry::Monads::Result::Success, nil] if no new enrollment_members are detected
      # @return [Dry::Monads::Result::Failure, Hash] if an error is encountered
      def detect_new_enrollment_members(customer_state, customer_new_state)
        enrolled_members = enrolled_members_for_insurance_coverage(customer_state[:insurance_coverage])
        new_enrolled_members = enrolled_members_for_insurance_coverage(customer_new_state[:insurance_coverage])
        return if enrolled_members == new_enrolled_members

        # new_enrolled_member_set = new_enrolled_members - enrolled_members
        new_enrolled_member_set =
          new_enrolled_members.each_with_object([]) do |nm, list|
            list << nm if enrolled_members.none? { |em| em.dig(:member, :hbx_id) == nm.dig(:member, :hbx_id) }
          end

        # new_enrolled_member_set =
        #   new_enrolled_members.reduce([]) do |list, new_member|
        #     list << new_member if enrolled_members.none? { |enrolled_member| enrolled_member == new_member }
        #     list
        #   end

        return nil if new_enrolled_member_set.empty?

        build_event('enrolled_members_added', new_enrolled_member_set, customer_state, customer_new_state) || []
      end

      def enrolled_members_for_insurance_coverage(insurance_coverage)
        insurance_coverage[:policies].reduce([]) do |policy_enrolled_members, policy|
          pol_members =
            policy[:marketplace_segments].reduce([]) do |mkt_enrolled_members, marketplace_segment|
              mkt_enrolled_members += marketplace_segment[:enrolled_members]
              mkt_enrolled_members
            end
          policy_enrolled_members += pol_members
          policy_enrolled_members
        end
      end
    end
  end
end
