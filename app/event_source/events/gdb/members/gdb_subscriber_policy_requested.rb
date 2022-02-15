# frozen_string_literal: true

module Events
  module Gdb
    module Members
      # GdbSubscriberPolicyRequested will register event publisher for Glue
      class GdbSubscriberPolicyRequested < EventSource::Event
        publisher_path 'publishers.gdb.members.member_publisher'
      end
    end
  end
end