# frozen_string_literal: true

module Publishers
  module UserFees
    # Publish {Events::UserFees::GdbTransactions} events
    class GdbTransactionsPublisher
      include ::EventSource::Publisher[amqp: 'edi_gateway.user_fees.gdb_transactions.events']

      register_event 'gdb_transaction_received'
    end
  end
end
