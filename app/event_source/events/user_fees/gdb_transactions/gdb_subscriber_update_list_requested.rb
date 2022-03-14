# frozen_string_literal: true

module Events
  module UserFees
    module GdbTransactions
      # Notification that a request to GludDB endpoint was requested to obtain a
      #   list of IDs for subscribers that were updated
      class GdbSubscriberUpdateListRequested < EventSource::Event
        publisher_path 'publishers.user_fees.gdb_transactions_publisher'
      end
    end
  end
end
