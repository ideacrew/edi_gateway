# frozen_string_literal: true

module Publishers
  # Publisher will send request payload to gdb for subscribers list
  module Gdb
    class SubscriberCoverageInformationPublisher
      include ::EventSource::Publisher[http: '/subscriber_coverage']

      register_event '/subscriber_coverage'
    end
  end
end