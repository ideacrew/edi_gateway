# frozen_string_literal: true

module Publishers
  # Publisher will send request payload to gdb for subscribers list
  module Gdb
    module Members
      class SubscribersListRequestedPublisher
        include ::EventSource::Publisher[http: '/enrolled_subjects/subscribers_list']

        register_event '/enrolled_subjects/subscribers_list'
      end
    end
  end
end