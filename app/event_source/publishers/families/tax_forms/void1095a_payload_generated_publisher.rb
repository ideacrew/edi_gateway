# frozen_string_literal: true

module Publishers
  module Families
    module Notices
      # Publisher will send void1095a_payload to Polypress to generate void1095a_notice.
      class Void1095aRequestedPublisher
        include ::EventSource::Publisher[amqp: 'edi_gateway.families.tax_forms.void1095a_payload']

        register_event 'generated'
      end
    end
  end
end
