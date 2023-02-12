# frozen_string_literal: true

module Publishers
  module EdiDatabase
    module DataStores
      # Publish {Events::EdiDatabase::IrsGroups} events
      class ContractHolderSubjectPublisher
        send(:include, ::EventSource::Publisher[amqp: 'edi_gateway.data_stores.contract_holder_subjects'])

        register_event 'edidb_update_requested'
      end
    end
  end
end
