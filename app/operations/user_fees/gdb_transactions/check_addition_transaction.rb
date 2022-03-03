# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module UserFees
  module GdbTransactions
    # Resolve whether passed transaction message is an enrollment addition
    #
    class CheckAdditionTransaction
      include Dry::Monads[:result, :do, :try]

      # @param [Hash] params the parameters to resolve message type
      # @option params [Hash] :message EDI Database transaction (required)
      # @return [Dry::Monad::Success] message is a addition
      # @return [Dry::Monad::Failure] message is not a addition
      def call(params)
        message = yield validate(params)
        result = yield classify_transaction(message)

        Success(result)
      end

      private

      def validate(message)
        return Success(message) if message.is_an_instance_of Hash
        Failure('hash expected')
      end

      def classify_transaction(message)
        binding.pry
        hbx_id = message[:customer][:hbx_id]
        new_customer = detect_new_customer(message[:customer])
        new_policies = detect_new_policies(message[:customer])
        new_tax_households = detect_new_tax_households(message[:customer])
        new_enrolled_members = detect_new_enrolled_members(message[:customer])
      end

      # add initial policy
      def detect_new_customer(customer)
        ::UserFees::Customer.find_by(hbx_id: customer[:hbx_id]) ? nil : customer
      end

      # add policies
      def detect_new_policies(customer)
        customer[:policies].reduce([]) do |new_policies, policy|
          new_policies << policy unless customer_policy_exists?(customer, policy)
        end
      end

      def customer_policy_exists?(customer, policy)
        ::UserFee::InsuranceCoverage.policy_id(customer, policy)
      end

      # add tax households
      def detect_new_tax_households(customer)
        customer[:tax_households].reduce([]) do |new_tax_households, tax_household|
          new_tax_households << tax_household unless customer_tax_household_exists?(hbx_id, message[:customer])
        end
      end

      def customer_tax_household_exists?(customer, tax_household)
        ::UserFee::InsuranceCoverage.tax_household(customer, tax_household)
      end
    end
  end
end
