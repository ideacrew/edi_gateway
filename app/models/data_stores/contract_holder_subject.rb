# frozen_string_literal: true

module DataStores
  class ContractHolderSubject
    include Mongoid::Document
    include Mongoid::Timestamps
    include DataStores::Transactable

    belongs_to :contract_holder_sync, counter_cache: true

    field :primary_person_hbx_id, type: String
    field :subscriber_policies, type: Array
    field :responsible_party_policies, type: Array

    index({ primary_person_hbx_id: 1 })
  end
end
