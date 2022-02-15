# frozen_string_literal: true

module Events
  module Gdb
    module Members
      # SubscriberPolicyResponseReceived will register event publisher for Glue
      class SubscriberPolicyResponseReceived < EventSource::Event
        publisher_path 'publishers.gdb.members.gdb_subscriber_policy_requested_publisher'
      end
    end
  end
end