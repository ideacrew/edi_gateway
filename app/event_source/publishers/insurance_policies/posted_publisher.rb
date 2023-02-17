# frozen_string_literal: true

module Publishers
  module InsurancePolicies
    # This class will register event
    class PostedPublisher
      include ::EventSource::Publisher[amqp: 'edi_gateway.insurance_policies']

      register_event 'posted'
    end
  end
end
