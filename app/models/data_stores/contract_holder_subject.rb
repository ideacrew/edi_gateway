# frozen_string_literal: true

module DataStores
  # A model to persist a DataStore synchronization subjects
  class ContractHolderSubject
    include Mongoid::Document
    include Mongoid::Timestamps
    include DataStores::Transactable

    belongs_to :contract_holder_sync, class_name: 'DataStores::ContractHolderSyncJob', counter_cache: true

    field :primary_person_hbx_id, type: String
    field :subscriber_policies, type: Array, default: -> { [] }
    field :responsible_party_policies, type: Array, default: -> { [] }
    field :status, type: Symbol, default: :created

    index({ primary_person_hbx_id: 1 })

    scope :by_primary_hbx_id, ->(hbx_id) { where(primary_person_hbx_id: hbx_id) }

    def subscriber_policies=(policies)
      return if policies.blank?

      all_policies = subscriber_policies.present? ? (subscriber_policies + policies) : policies
      write_attribute(:subscriber_policies, all_policies.uniq)
    end

    def responsible_party_policies=(policies)
      return if policies.blank?

      all_policies = responsible_party_policies.present? ? (responsible_party_policies + policies) : policies
      write_attribute(:responsible_party_policies, all_policies.uniq)
    end
  end
end
