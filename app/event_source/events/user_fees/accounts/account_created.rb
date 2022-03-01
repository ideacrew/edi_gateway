# frozen_string_literal: true

module Events
  module UserFees
    module Accounts
      # This class will register event
      class AccountCreated < EventSource::Event
        publisher_path 'publishers.user_fees.account_publisher'
      end
    end
  end
end
