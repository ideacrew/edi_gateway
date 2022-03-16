# frozen_string_literal: true

module Events
  module EdiDatabase
    module Transactions
      # Notification that a {UserFees::GdbTransaction} was received
      class TransactionReceived < EventSource::Event
        publisher_path 'publishers.edi_database.transactions.transactions_publisher'
      end
    end
  end
end
