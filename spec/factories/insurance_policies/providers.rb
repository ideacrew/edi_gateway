# frozen_string_literal: true

FactoryBot.define do
  factory :insurance_provider, class: InsurancePolicies::InsuranceProvider do
    title { "ABC carrier" }
    fein { "311705652" }
    hios_id { "123456" }
  end
end
