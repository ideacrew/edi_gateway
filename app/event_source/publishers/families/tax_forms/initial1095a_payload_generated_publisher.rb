# frozen_string_literal: true

module Publishers
  module Families
    module Notices
      # Publisher will send initial1095a_payload to Polypress to generate initial1095a_notice.
      class Initial1095aRequestedPublisher
        include ::EventSource::Publisher[amqp: 'edi_gateway.families.tax_forms.initial1095a_payload']

        register_event 'generated'
      end
    end
  end
end
