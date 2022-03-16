# frozen_string_literal: true

module Events
  module EdiDatabase
    module Transactions
      # Notification that a request to GludDB endpoint was requested to obtain a
      #   list of IDs for subscribers that were updated
      class SubscriberUpdateListRequested < EventSource::Event
        publisher_path 'publishers.edi_database.transactions_publisher'
      end
    end
  end
end
