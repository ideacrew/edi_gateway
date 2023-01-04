# frozen_string_literal: true

FactoryBot.define do
  factory :insurance_product, class: InsurancePolicies::InsuranceProduct do
    name { "ABC plan" }
    sequence(:hios_plan_id, &:to_s)
    coverage_type { "health" }
    metal_level { "silver" }
    market_type { "individual" }
    plan_year { Date.today.year }
    insurance_provider
  end
end
