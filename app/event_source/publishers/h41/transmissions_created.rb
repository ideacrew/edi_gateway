# frozen_string_literal: true

module Publishers
  module H41
    class TransmissionsCreatedPublisher
      send(:include, ::EventSource::Publisher[amqp: 'fdsh.h41.transmissions'])

      register_event 'created'
    end
  end
end
