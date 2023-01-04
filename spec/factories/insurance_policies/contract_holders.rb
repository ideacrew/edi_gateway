# frozen_string_literal: true

FactoryBot.define do
  factory :contract_holder, class: InsurancePolicies::ContractHolder do
    sequence(:account_id, &:to_s)
  end
end
