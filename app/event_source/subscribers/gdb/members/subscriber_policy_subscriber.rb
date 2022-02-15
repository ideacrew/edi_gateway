# frozen_string_literal: true

module Subscribers
  module Gdb
    module Members
      # Receive payload and publish event to glue to fetch policy information
      class SubscriberPolicySubscriber
        include ::EventSource::Subscriber[amqp: 'edi_gateway.gdb.members']
        extend EventSource::Logging

        subscribe(:on_gdb_subscriber_policy_requested) do |delivery_info, properties, payload|
          logger.info "************* Received response #{delivery_info}, Headers - #{properties}, Body - #{payload}"
          json_response = JSON.parse(payload, { symbolize_names: true })
          ::Gdb::Members::RequestGdbSubscriberPolicy.new.call(json_response)
          ack(delivery_info.delivery_tag)
        rescue StandardError => e
          logger.error "error backtrace: #{e.inspect}, #{e.backtrace}"
          ack(delivery_info.delivery_tag)
        end
      end
    end
  end
end
