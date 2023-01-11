# frozen_string_literal: true

module Publishers
  module Families
    module Notices
      # Publisher will send request to Polypress to generate corrected_notice for ivl_tax 1095a.
      class Corrected1095aRequestedPublisher
        include ::EventSource::Publisher[amqp: 'edi_gateway.families.tax_forms.corrected1095a_payload']

        register_event 'generated'
      end
    end
  end
end
