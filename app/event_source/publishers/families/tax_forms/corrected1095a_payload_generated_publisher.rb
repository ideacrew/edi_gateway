# frozen_string_literal: true

module Publishers
  module Families
    module Notices
      # Publisher will send corrected1095a_payload to Polypress to generate corrected1095a_notice.
      class Corrected1095aRequestedPublisher
        include ::EventSource::Publisher[amqp: 'edi_gateway.families.tax_forms.corrected1095a_payload']

        register_event 'generated'
      end
    end
  end
end
