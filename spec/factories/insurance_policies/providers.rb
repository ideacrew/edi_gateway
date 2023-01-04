# frozen_string_literal: true

FactoryBot.define do
  factory :insurance_provider, class: InsurancePolicies::InsuranceProvider do
    title { "ABC carrier" }
    sequence(:hios_id, &:to_s)
  end
end
