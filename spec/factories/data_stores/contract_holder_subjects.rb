# frozen_string_literal: true

FactoryBot.define do
  factory :contract_holder_subject, class: DataStores::ContractHolderSubject do
    sequence(:primary_person_hbx_id)
  end
end
  