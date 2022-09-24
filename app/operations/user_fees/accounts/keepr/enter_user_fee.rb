# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module UserFees
  module Accounts
    module Keepr
      # Add a {UserFees::Accounts::UserFee} transaction to one or more Accounts
      class EnterUserFee
        send(:include, Dry::Monads[:result, :do])

        # @param [Hash] params the parameters of a UserFee
        # @option params [AcaEntities::Ledger::AccountEntry] :account_entry required
        # @return [Dry::Monad::Success] UserFeeTransaction created
        # @return [Dry::Monad::Failure] failed to create UserFeeTransaction
        def call(params)
          values = yield validate(params)
          balance = yield enter_transaction(values)

          Success(balance)
        end

        private

        def validate(params)
          # AcaEntities::Ledger::Contracts::AccountEntryContract.new.call(params[:account_entry])
          Success(params)
        end

        def enter_transaction(values)
          values[:journal].update! permanent: true
          post = Keepr::Posting.new values[:account_entry][:debits].first
        end
      end
    end
  end
end
