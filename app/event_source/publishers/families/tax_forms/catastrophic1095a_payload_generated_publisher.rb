# frozen_string_literal: true

module Publishers
  module Families
    module Notices
      # Publisher will send catastrophic1095a_payload to Polypress to generate catastrophic1095a_notice.
      class Catastrophic1095aRequestedPublisher
        include ::EventSource::Publisher[amqp: 'edi_gateway.families.tax_forms.catastrophic1095a_payload']

        register_event 'generated'
      end
    end
  end
end
