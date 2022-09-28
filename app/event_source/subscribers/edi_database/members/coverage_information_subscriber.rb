# frozen_string_literal: true

module Subscribers
  module EdiDatabase
    module Members
      # Receive payload and publish event to glue to fetch policy information
      class CoverageInformationSubscriber
        include ::EventSource::Subscriber[amqp: 'edi_gateway.edi_database.members']
        extend EventSource::Logging

        subscribe(:on_subscriber_coverage_information_requested) do |delivery_info, properties, payload|
          logger.info "************* Received response #{delivery_info}, Headers - #{properties}, Body - #{payload}"
          json_response = JSON.parse(payload, { symbolize_names: true })
          ::Reports::RequestGdbForCoverageInformation.new.call(json_response)
          ack(delivery_info.delivery_tag)
        rescue StandardError => e
          logger.error "error backtrace: #{e.inspect}, #{e.backtrace}"
          ack(delivery_info.delivery_tag)
        end
      end
    end
  end
end
