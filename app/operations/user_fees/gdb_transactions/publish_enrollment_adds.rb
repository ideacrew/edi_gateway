# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'securerandom'

module UserFees
  module GdbTransactions
    # Inspect a GlueDB enrollment transaction comparing it against the
    # existing state to determine whether it indicates enrollment
    # add activities. If so, publish a corresponding enrollment add event
    class PublishEnrollmentAdds
      include Dry::Monads[:result, :do, :try]
      include EventSource::Command

      # @param [AcaEntities::Ledger::GdbTransaction] params a GlueDB enrollment transaction
      # @return [Dry::Monads::Success, Array<Events::UserFees::EnrollmentAdds::InitialEnrollmentAdded>] if transaction is an initial enrollment
      # @return [Dry::Monads::Success, Array<Events::UserFees::EnrollmentAdds::PoliciesAdded>] if transaction includes one or more policy adds
      # @return [Dry::Monads::Success, Array<Events::UserFees::EnrollmentAdds::TaxHouseholdsAdded>] if transaction includes one or more tax household adds
      # @return [Dry::Monads::Failure] unable to process GdbTransaction
      def call(params)
        params = yield validate(params)
        events = yield inspect_transaction(params)
        published_events = yield publish_events(events)

        Success(published_events)
      end

      private

      # Schema-verify the integrity of the passed parameters
      # @param [Hash] :params a GlueDB enrollment transaction
      # @return [Dry::Validation::Result]
      def validate(params)
        AcaEntities::Ledger::Contracts::GdbTransactionContract.new.call(params)
      end

      def inspect_transaction(params)
        customer_new_state = (params[:customer])
        customer_state = fetch_customer(customer_new_state)

        return Success([detect_initial_enrollment(customer_state, customer_new_state)]) unless customer_state.present?
        policy_events = detect_new_policies(customer_state, customer_new_state)
        tax_household_events = detect_new_tax_households(customer_state, customer_new_state)

        Success([policy_events, tax_household_events].compact)
      rescue StandardError => e
        Failure[:transaction_parse_error, params: customer_new_state, error: e.to_s, backtrace: e.backtrace]
      end

      def fetch_customer(customer)
        ::UserFees::Customer.find_by(hbx_id: customer[:hbx_id]).to_entity.to_h
      end

      # Compare existing with new customer states and detect an added initial enrollment
      #
      # @param [AcaEntities::Ledger::Customer] :customer_state existing customer attributes
      # @param [AcaEntities::Ledger::Customer] :customer_new_state new customer attributes
      #
      # @return [Dry::Monads::Result::Success, Array<Events::UserFees::EnrollmentAdds::InitialEnrollmentAdded>] if a new enrollment is detected
      # @return [Dry::Monads::Result::Success, nil] if initial enrollment isn't detected
      # @return [Dry::Monads::Result::Failure, Hash] if an error is encountered
      def detect_initial_enrollment(customer_state, customer_new_state)
        build_event('initial_enrollment_added', {}, customer_state, customer_new_state) if customer_state.empty?
      end

      # Compare existing with new customer states and detect added tax_households
      #
      # @param [AcaEntities::Ledger::Customer] :customer_state existing customer attributes
      # @param [AcaEntities::Ledger::Customer] :customer_new_state new customer attributes
      #
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

      # Compare existing with new customer states and detect added policies
      #
      # @param [AcaEntities::Ledger::Customer] :customer_state existing customer attributes
      # @param [AcaEntities::Ledger::Customer] :customer_new_state new customer attributes
      #
      # @return [Dry::Monads::Result::Success, Array<Events::UserFees::EnrollmentAdds::PoliciesAdded>] if new policies are detected
      # @return [Dry::Monads::Result::Success, nil] if no new policies are detected
      # @return [Dry::Monads::Result::Failure, Hash] if an error is encountered
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

      def publish_events(events)
        Success(events.each { |event| event.success.publish })
      rescue StandardError => e
        Failure[:event_publish_error, params: customer_new_state, error: e.to_s, backtrace: e.backtrace]
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
