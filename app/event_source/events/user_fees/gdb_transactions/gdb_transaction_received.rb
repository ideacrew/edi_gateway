# frozen_string_literal: true

module Events
  module UserFees
    module GdbTransactions
      # This class will register event
      class GdbTransactionReceived < EventSource::Event
        publisher_path 'publishers.user_fees.gdb_transaction_publisher'
      end
    end
  end
end
