# frozen_string_literal: true

module Publishers
  module Families
    module Notices
      # Publisher will send catastrophic1095a_payload to Polypress to generate catastrophic1095a_notice.
      class TaxForm1095aPayloadGeneratedPublisher
        include ::EventSource::Publisher[amqp: 'edi_gateway.families.tax_form1095a']

        register_event 'initial_payload_generated'
        register_event 'void_payload_generated'
        register_event 'corrected_payload_generated'
        register_event 'catastrophic_payload_generated'
      end
    end
  end
end
