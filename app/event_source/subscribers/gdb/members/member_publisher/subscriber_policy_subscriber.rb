# frozen_string_literal: true

module Subscribers
  module Gdb
    module Members
      module MemberPublisher
        # Receive payload and publish event to glue to fetch policy information
        class SubscriberPolicySubscriber
          include ::EventSource::Subscriber[amqp: 'edi_gateway.gdb.members.member_publisher']
          extend EventSource::Logging

          subscribe(:on_gdb_subscriber_policy_requested) do |delivery_info, properties, payload|
            logger.info "Received response #{delivery_info}, Body - #{properties}, Headers - #{payload}"
          rescue StandardError => e
            logger.error "error backtrace: #{e.inspect}, #{e.backtrace}"
          end
        end
      end
    end
  end
end
