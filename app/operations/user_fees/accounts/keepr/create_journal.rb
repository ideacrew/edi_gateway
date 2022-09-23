# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module UserFees
  module Accounts
    module Keepr
      # Create a {Keepr::Journal}
      class CreateJournal
        send(:include, Dry::Monads[:result, :do])

        # @param [Hash] params the parameters to create {Keepr::Account}
        # @option params [Integer] :number (required)
        # @option params [String] :name (required)
        # @option params [Date] :date (required)
        # @option params [String] :subject (optional)
        # @option params [String] :note (optional)
        # @option params [AcaEntities::Ledger::Types::KeeprAccountKind] :kind (required)
        # @option params [Keepr::Account] :parent (optional)
        # @return [Dry::Monads::Result::Success] if account created
        # @return [Dry::Monads::Result::Failure] if account create errored
        def call(params)
          values = yield validate(params)
          account = yield create_account(values)

          Success(account)
        end

        private

        def validate(params)
          AcaEntities::Ledger::Contracts::AccountJournalContract.new.call(params)
        end

        def create_account(values)
          account = ::Keepr::Account.create(values.to_h)
          Success(account)
        end
      end
    end
  end
end
