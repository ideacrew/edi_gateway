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
        logger.info "Polypress: invoked Tax1095aPayloadRequestedSubscriber with delivery_info:
                              #{delivery_info} routing_key: #{routing_key}"
        payload = JSON.parse(response, symbolize_names: true)

        result = ::Tax1095a::Transformers::InsurancePolicies::Cv3Family.new.call({ tax_year: payload[:tax_year],
                                                                                   tax_form_type: payload[:tax_form_type],
                                                                                   irs_group_id: payload[:irs_group_id] })

        if result.success?
          logger.info "Polypress: Tax1095aPayloadRequestedSubscriber; acked for #{routing_key}"
        else
          errors = if result.is_a?(String)
                     result
                   elsif result.failure.is_a?(String)
                     result.failure
                   else
                     result.failure.errors.to_h
                   end
          logger.error(
            "Polypress: Tax1095aPayloadRequestedSubscriber_error;
                        nacked due to:#{errors}; for routing_key: #{routing_key}, payload: #{payload}"
          )
        end
        ack(delivery_info.delivery_tag)
      rescue StandardError, SystemStackError => e
        logger.error(
          "Polypress: Tax1095aPayloadRequestedSubscriber_error: nacked due to backtrace:
                    #{e.backtrace}; for routing_key: #{routing_key}, response: #{response}"
        )
        ack(delivery_info.delivery_tag)
      end
    end
  end
end
