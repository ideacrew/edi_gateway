# frozen_string_literal: true

module Publishers
  module Families
    module Notices
      # Publisher will send catastrophic1095a_payload to Polypress to generate catastrophic1095a_notice.
      class Catastrophic1095aRequestedPublisher
        include ::EventSource::Publisher[amqp: 'edi_gateway.families.tax_form1095a']

        register_event 'Initial_payload_generated'
        register_event 'void_payload_generated'
        register_event 'corrected_payload_generated'
        register_event 'catastrophic_payload_generated'
      end
    end
  end
end
