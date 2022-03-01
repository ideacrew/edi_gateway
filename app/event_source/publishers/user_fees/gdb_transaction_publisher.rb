# frozen_string_literal: true

module Publishers
  module UserFees
    # Publish {UserFees::GdbTransaction} events
    class GdbTransactionPublisher
      include ::EventSource::Publisher[amqp: 'edi_gateway.user_fees.gdb_transaction.events']

      register_event 'gdb_transaction_received'
    end
  end
end
