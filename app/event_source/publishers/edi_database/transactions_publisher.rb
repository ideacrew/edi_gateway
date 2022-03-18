# frozen_string_literal: true

module Publishers
  module EdiDatabase
    module Transactions
      # Publish {Events::EdiDatabase::Transactions} events
      class TransactionsPublisher
        include ::EventSource::Publisher[amqp: 'edi_gateway.edi_database.transactions']

        # register_event 'subscriber_update_list_requested'
        # register_event 'transaction_requested'
        # register_event 'transaction_received'
        # register_event 'gdb_transaction_created'
      end
    end
  end
end
