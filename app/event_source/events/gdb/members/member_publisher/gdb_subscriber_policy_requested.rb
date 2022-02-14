# frozen_string_literal: true

module Events
  module Gdb
    module Members
      module MemberPublisher
        # GdbSubscriberPolicyRequested will register event publisher for Glue
        class GdbSubscriberPolicyRequested < EventSource::Event
          publisher_path 'publishers.gdb.members.member_publisher.gdb_subscriber_policy_requested_publisher'
        end
      end
    end
  end
end