# frozen_string_literal: true

module Publishers
  # Publisher will send request payload to gdb for subscribers list
  module Gdb
    class SubscriberCoverageInformationPublisher
      include ::EventSource::Publisher[http: '/api/event_source/enrolled_subjects/show']

      register_event '/api/event_source/enrolled_subjects/show'
    end
  end
end