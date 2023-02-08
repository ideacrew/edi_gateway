# frozen_string_literal: true

module DataStores
  # A model to persist a DataStore synchronization subjects
  class ContractHolderSubject
    include Mongoid::Document
    include Mongoid::Timestamps
    # include DataStores::Transactable

    belongs_to :contract_holder_sync, class_name: 'DataStores::ContractHolderSyncJob', counter_cache: true

    field :primary_person_hbx_id, type: String
    field :subscriber_policies, type: Array
    field :responsible_party_policies, type: Array

    index({ primary_person_hbx_id: 1 })

    scope :by_primary_hbx_id, ->(hbx_id) { where(primary_person_hbx_id: hbx_id) }

    def subscriber_policies=(policies)
      return if subscriber_policies.present? || policies.blank?

      write_attribute(:subscriber_policies, policies.uniq)
    end

    def responsible_party_policies=(policies)
      return if responsible_party_policies.present? || policies.blank?

      write_attribute(:responsible_party_policies, policies.uniq)
    end
  end
end
