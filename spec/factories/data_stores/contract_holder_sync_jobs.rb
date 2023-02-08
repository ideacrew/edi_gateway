# frozen_string_literal: true

FactoryBot.define do
  factory :contract_holder_sync_job, class: DataStores::ContractHolderSyncJob do
    started_at { DateTime.now }
    completed_at { DateTime.now + 6.hours }
  end
end
