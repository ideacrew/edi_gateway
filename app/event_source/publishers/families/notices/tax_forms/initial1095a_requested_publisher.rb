# frozen_string_literal: true

module Publishers
  module Families
    module Notices
      module TaxForms
        # Publisher will send request to Polypress to generate initial_notice for ivl_tax 1095a.
        class Initial1095aRequestedPublisher
          include ::EventSource::Publisher[amqp: 'edi_gateway.families.notices.tax_forms.initial1095a']

          register_event 'requested'
        end
      end
    end
  end
end
