# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'securerandom'

module EdiDatabase
  module Transactions
    # Generate a Glue DB transaction event
    class CreateGdbTransaction
      send(:include, Dry::Monads[:result, :do])
      include EventSource::Command

      def call(params)
        values = yield validate(params)
        event = yield publish_event(values)

        Success(event)
      end

      private

      def validate(params)
        AcaEntities::Ledger::Contracts::GdbTransactionContract.new.call(params)
      end

      def publish_event(values)
        event('events.edi_database.transactions.gdb_transaction_created', attributes: values.to_h)
      end
    end
  end
end
