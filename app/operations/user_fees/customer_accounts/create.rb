# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module UserFees
  module CustomerAccounts
    # Persist a new {UserFees::CustomerAccount} record in the database
    class Create
      include Dry::Monads[:result, :do, :try]

      # @param [Hash] opts the parameters used to search for the CustomerAccount
      # @option opts [Hash] :customer_account required
      # @return [Dry::Monad::Success] customer_account record created
      # @return [Dry::Monad::Failure] failed to create customer_account record
      def call(params)
        values = yield validate(params)
        customer_account = yield create(values)

        Success(customer_account)
      end

      private

      def validate(params)
        AcaEntities::Ledger::Contracts::CustomerAccountContract.new.call(params[:customer_account])
      end

      def create(values)
        attrs = values.to_h
        customer_id = attrs[:customer][:hbx_id]
        if UserFees::CustomerAccount.by_customer_id(value: customer_id).count > 0
          return Failure("customer_id already exists: #{customer_id}")
        end
        customer_account = UserFees::CustomerAccount.create(attrs)
        customer_account ? Success(customer_account) : Failure(customer_account)
      end
    end
  end
end
