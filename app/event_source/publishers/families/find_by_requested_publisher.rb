# frozen_string_literal: true

module Publishers
  module Families
    # This class will register event
    class FindByRequestedPublisher
      include ::EventSource::Publisher[amqp: 'edi_gateway.families']

      register_event 'find_by_requested'
    end
  end
end
