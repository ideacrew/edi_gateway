# frozen_string_literal: true

module Subscribers
  module InsurancePolicies
    # Subscriber will receive tax1095a_payload.requested event from EDI gateway to generate 1095a tax_payload
    class Tax1095aPayloadRequestedSubscriber
      include EventSource::Command
      include EventSource::Logging
      include ::EventSource::Subscriber[amqp: 'edi_gateway.insurance_policies.tax1095a_payload']

      subscribe(:on_requested) do |delivery_info, _metadata, response|
        routing_key = delivery_info[:routing_key]
        subscriber_logger = subscriber_logger_for(:on_tax1095a_payload_requested)
        payload = JSON.parse(response, symbolize_names: true)

        result = ::Tax1095a::Transformers::InsurancePolicies::Cv3Family.new.call({ tax_year: payload[:tax_year],
                                                                                   tax_form_type: payload[:tax_form_type],
                                                                                   irs_group_id: payload[:irs_group_id] })

        if result.success?
          subscriber_logger.info(
            "OK: :Published successfully and acked for irs_group #{payload[:irs_group_id]}, for routing_key: #{routing_key}"
          )
        else
          errors = if result.is_a?(String)
                     result
                   elsif result.failure.is_a?(String)
                     result.failure
                   else
                     result.failure.errors.to_h
                   end
          subscriber_logger.error(
            "Error: Unable to publish message due to errors #{errors} for routing_key: #{routing_key}, payload: #{payload}"
          )
        end
        ack(delivery_info.delivery_tag)
      rescue StandardError, SystemStackError => e
        subscriber_logger.error(
          "Polypress: Tax1095aPayloadRequestedSubscriber_error: nacked due to backtrace:
                    #{e.backtrace.inspect}; for routing_key: #{routing_key}, response: #{response}; errors: #{e.message}"
        )
        ack(delivery_info.delivery_tag)
      end

      private

      def subscriber_logger_for(event)
        Logger.new(
          "#{Rails.root}/log/#{event}_#{Date.today.strftime('%Y_%m_%d')}.log"
        )
      end
    end
  end
end
