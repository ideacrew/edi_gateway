
# frozen_string_literal: true

module Publishers
  module Families
    module AllInsurancePolicies
      # This class will register event
      class PostedPublisher
        include ::EventSource::Publisher[amqp: 'edi_gateway.families.all_insurance_policies']

        register_event 'posted'
      end
    end
  end
end