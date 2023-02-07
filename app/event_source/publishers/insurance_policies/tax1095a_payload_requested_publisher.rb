# frozen_string_literal: true

module Publishers
  module InsurancePolicies
    # Publisher will send tax1095a_payload.requested event to edi gateway to generate payload.
    class Tax1095aPayloadRequestedPublisher
      include ::EventSource::Publisher[amqp: 'edi_gateway.insurance_policies.tax1095a_payload']

      register_event 'requested'
    end
  end
end
