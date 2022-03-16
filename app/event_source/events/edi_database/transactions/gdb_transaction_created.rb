# frozen_string_literal: true

module Events
  module EdiDatabase
    module Transactions
      # Notification that a {EdiDatabase::Transactions::GdbTransactionCreated} was requested
      class GdbTransactionCreated < EventSource::Event
        publisher_path 'publishers.edi_database.transactions.transactions_publisher'
      end
    end
  end
end
