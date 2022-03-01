# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module UserFees
  # Accept an EDI Database enrollment transaction, classify into transaction types,
  # and publish correllated {EnrollmentUpdated} events
  class CreateEnrollmentUpdate
    include Dry::Monads[:result, :do, :try]

    # @param [Hash] opts a {GlueDbEnrollmentTransactionReceived} event
    # @option opts [Hash] :gdb_enrollment_transaction required
    # @return [Dry::Monad::Success] array of published EnrollmentUpdated events
    # @return [Dry::Monad::Failure] failed to publish EnrollmentUpdated events for this transaction
    def call(params)
      message = yield validate(params)
      transactions = yield classify_transaction(message)
      events = yield publish_events(transactions)

      Success(events)
    end

    private

    def transaction_chain
      [
        UserFees::GdbTransactions::CheckAdditionTransaction,
        UserFees::GdbTransactions::CheckTerminationTransaction,
        UserFees::GdbTransactions::CheckReinstatedTransaction,
        UserFees::GdbTransactions::CheckChangedTransaction
      ]
    end

    def validate(params)
      AcaEntities::Ledger::Contracts::CustomerContract.new.call(params[:customer])
    end

    def classify_transaction(values)
      # enrollment_changed
      # enrollment_added
      # enrollment_terminated
      # enrollment_reinstated
    end

    def publish_events(transactions); end
  end
end
