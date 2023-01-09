# frozen_string_literal: true

module Publishers
  module InsurancePolicies
    module Notices
      module IvlTax1095A
        # Publisher will send request to Polypress to generate catastrophic_notice for ivl_tax 1095a.
        class CatastrophicNoticeGenerationRequestedPublisher
          include ::EventSource::Publisher[amqp: 'edi_gateway.insurance_policies.notices.ivl_tax_1095a.catastrophic_notice_generation']

          register_event 'requested'
        end
      end
    end
  end
end
