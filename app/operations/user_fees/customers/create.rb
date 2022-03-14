# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module UserFees
  module Customers
    # Persist a new {UserFees::Customer} record in the database
    class Create
      send(:include, Dry::Monads[:result, :do])

      # @param [Hash] params the parameters used to create a new Customer
      # @option params [AcaEntities::Ledger::Customer] :customer required
      # @return [Dry::Monad::Success] Customer record created
      # @return [Dry::Monad::Failure] failed to create Customer record
      def call(params)
        values = yield validate(params)
        customer = yield create(values)

        Success(customer)
      end

      private

      def validate(params)
        AcaEntities::Ledger::Contracts::CustomerContract.new.call(params[:customer])
      end

      def create(values)
        attrs = values.to_h
        customer_attrs = attrs.slice(:first_name, :last_name, :hbx_id, :customer_role, :insurance_coverage, :is_active)
        account = ::Keepr::Account.new(attrs[:account])

        customer = UserFees::Customer.create!(customer_attrs.merge(account: account))
        customer ? Success(customer) : Failure(customer)
      end
    end
  end
end
