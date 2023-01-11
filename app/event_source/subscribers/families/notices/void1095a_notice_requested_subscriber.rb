# frozen_string_literal: true

module Subscribers
  module Families
    module Notices
      # Subscriber will receive void1095a_notice event from enroll to generate 1095a tax_payload
      class Void1095aNoticeRequestedSubscriber
        include EventSource::Logging
        include ::EventSource::Subscriber[amqp: 'enroll.families.notices.void1095a_notice']

        subscribe(:on_requested) do |delivery_info, _metadata, response|
          routing_key = delivery_info[:routing_key]
          logger.info "Polypress: invoked Void1095aNoticeRequestedSubscriber with delivery_info:
                      #{delivery_info} routing_key: #{routing_key}"

          payload = JSON.parse(response, symbolize_names: true)
          result = Success(true) # TODO: Add domain model that builds respective payload and publish event to polypress

          if result.success?
            logger.info "Polypress: Catastrophic1095aNoticeRequestedSubscriber; acked for #{routing_key}"
          else
            errors = if result.is_a?(String)
                       result
                     elsif result.failure.is_a?(String)
                       result.failure
                     else
                       result.failure.errors.to_h
                     end
            logger.error(
              "Polypress: Catastrophic1095aNoticeRequestedSubscriber_error;
                      nacked due to:#{errors}; for routing_key: #{routing_key}, payload: #{payload}"
            )
          end
          ack(delivery_info.delivery_tag)
        rescue StandardError, SystemStackError => e
          logger.error(
            "Polypress: Void1095aNoticeRequestedSubscriber_error: nacked due to backtrace:
                  #{e.backtrace}; for routing_key: #{routing_key}, response: #{response}"
          )
          ack(delivery_info.delivery_tag)
        end
      end
    end
  end
end
