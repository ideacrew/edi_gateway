# frozen_string_literal: true

module Publishers
  # Publisher will send request payload to gdb for subscribers list
  module EdiDatabase
    module Members
      class SubscriberCoverageInformationPublisher
        include ::EventSource::Publisher[amqp: 'edi_gateway.edi_database.members']

        register_event 'subscriber_coverage_information_requested'
      end
    end
  end
end