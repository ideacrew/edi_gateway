# frozen_string_literal: true

FactoryBot.define do
  factory :contract_holder_sync, class: DataStores::ContractHolderSyncJob do
    time_span_start { DateTime.now }
    time_span_end { DateTime.now + 24.hours }
    start_at { DateTime.now }
    end_at { DateTime.now + 5.minutes }
  end
end
