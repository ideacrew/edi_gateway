# frozen_string_literal: true

module Publishers
  # Publisher will send request payload to gdb for subscribers list
  module Gdb
    module Members
      module MemberPublisher
        class GdbSubscriberPolicyRequestedPublisher
          include ::EventSource::Publisher[amqp: 'edi_gateway.gdb.members.member_publisher']

          register_event 'gdb_subscriber_policy_requested'
        end
      end
    end
  end
end