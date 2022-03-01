# frozen_string_literal: true

module Events
  module UserFees
    module Customers
      # This class will register event
      class CustomerCreated < EventSource::Event
        publisher_path 'publishers.user_fees.customer_publisher'
      end
    end
  end
end
