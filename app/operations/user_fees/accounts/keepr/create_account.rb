# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module UserFees
  module Accounts
    module Keepr
      # Create a {Keepr::Account}
      class CreateAccount
        send(:include, Dry::Monads[:result, :do])

        # @param [Hash] params the parameters to create {Keepr::Account}
        # @option params [Integer] :number (required)
        # @option params [String] :name (required)
        # @option params [AcaEntities::Ledger::Types::KeeprAccountKind] :kind (required)
        # @option params [Keepr::Account] :parent (optional)
        # @return [Dry::Monads::Result::Success] if account created
        # @return [Dry::Monads::Result::Failure] if account create errored
        def call(params)
          values = yield validate(params)
          account = yield create_account(values.to_h)

          Success(account)
        end

        private

        def validate(params)
          AcaEntities::Ledger::Contracts::AccountContract.new.call(params)
        end

        def create_account(values)
          account_exists = ::Keepr::Account.find_by(number: values[:number]) || false
          return Failure("account already exists: #{account_exists}") if account_exists

          account = ::Keepr::Account.create!(values)
          Success(account)
        end
      end
    end
  end
end
