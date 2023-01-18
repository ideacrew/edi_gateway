# frozen_string_literal: true

module Subscribers
  module Families
    module Notices
      # Subscriber will receive initial1095a_notice event from enroll to generate 1095a tax_payload
      class Tax1095aNoticeRequestedSubscriber
        include EventSource::Command
        include EventSource::Logging
        include ::EventSource::Subscriber[amqp: 'enroll.families.notices.ivl_tax1095a']

        subscribe(:on_enroll_families_notices_ivl_tax1095a) do |delivery_info, _metadata, response|
          routing_key = delivery_info[:routing_key]
          logger.info "Polypress: invoked Tax1095aNoticeRequestedSubscriber with delivery_info:
                        #{delivery_info} routing_key: #{routing_key}"
          payload = JSON.parse(response, symbolize_names: true)
          result = ::Tax1095a::FetchAndPublishIrsGroups.new.call({ tax_year: payload[:tax_year],
                                                                   tax_form_type: payload[:tax_form_type] })

          if result.success?
            logger.info "Polypress: Tax1095aNoticeRequestedSubscriber; acked for #{routing_key}"
          else
            errors = if result.is_a?(String)
                       result
                     elsif result.failure.is_a?(String)
                       result.failure
                     else
                       result.failure.errors.to_h
                     end
            logger.error(
              "Polypress: Tax1095aNoticeRequestedSubscriber_error;
                      nacked due to:#{errors}; for routing_key: #{routing_key}, payload: #{payload}"
            )
          end
          ack(delivery_info.delivery_tag)
        rescue StandardError, SystemStackError => e
          logger.error(
            "Polypress: Tax1095aNoticeRequestedSubscriber_error: nacked due to backtrace:
                  #{e.backtrace}; for routing_key: #{routing_key}, response: #{response}"
          )
          ack(delivery_info.delivery_tag)
        end
      end
    end
  end
end
