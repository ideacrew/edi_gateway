# frozen_string_literal: true

module Events
  module DataStores
    module ContractHolderSubjects
      # Notification that a {EdiDatabase::Transactions::GdbTransactionCreated} was requested
      class EdidbUpdateRequested < EventSource::Event
        publisher_path 'publishers.data_stores.contract_holder_subject_publisher'
      end
    end
  end
end
