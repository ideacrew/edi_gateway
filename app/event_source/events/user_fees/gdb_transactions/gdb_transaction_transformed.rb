# frozen_string_literal: true

module Events
  module UserFees
    module GdbTransactions
      # Notification that a {UserFees::GdbTransaction} was transformed
      class GdbTransactionTransformed < EventSource::Event
        publisher_path 'publishers.user_fees.gdb_transactions_publisher'
      end
    end
  end
end
