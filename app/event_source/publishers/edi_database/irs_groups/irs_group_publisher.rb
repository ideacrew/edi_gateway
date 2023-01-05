# frozen_string_literal: true

module Publishers
  module EdiDatabase
    module IrsGroups
      # Publish {Events::EdiDatabase::IrsGroups} events
      class IrsGroupPublisher
        send(:include, ::EventSource::Publisher[amqp: 'edi_gateway.edi_database.irs_groups'])

        register_event 'policy_and_insurance_agreement_created'
      end
    end
  end
end
