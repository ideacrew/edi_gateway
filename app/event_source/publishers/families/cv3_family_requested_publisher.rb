# frozen_string_literal: true

module Publishers
  module Families
    class Cv3FamilyRequestedPublisher
      send(:include, ::EventSource::Publisher[amqp: 'edi_gateway.families.cv3_family'])

      register_event 'requested'
    end
  end
end
