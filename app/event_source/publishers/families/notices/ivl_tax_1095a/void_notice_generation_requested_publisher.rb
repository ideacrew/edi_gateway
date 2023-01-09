# frozen_string_literal: true

module Publishers
  module InsurancePolicies
    module Notices
      module IvlTax1095A
        # Publisher will send request to Polypress to generate void_notice for ivl_tax 1095a.
        class VoidNoticeGenerationRequestedPublisher
          include ::EventSource::Publisher[amqp: 'edi_gateway.insurance_policies.notices.ivl_tax_1095a.void_notice_generation']

          register_event 'requested'
        end
      end
    end
  end
end
