# frozen_string_literal: true

module Publishers
  # Publisher will send request payload to gdb for subscribers list
  module Gdb
    class SubscribersListPublisher
      include ::EventSource::Publisher[http: '/subscribers_list']

      register_event '/subscribers_list'
    end
  end
end