# frozen_string_literal: true

module Publishers
  # Publisher will send request payload to gdb for subscribers list
  module EdiDatabase
    class SubscribersListPublisher
      include ::EventSource::Publisher[http: '/api/event_source/enrolled_subjects']

      register_event '/api/event_source/enrolled_subjects'
    end
  end
end