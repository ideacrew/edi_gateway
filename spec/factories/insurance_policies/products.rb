# frozen_string_literal: true

FactoryBot.define do
  factory :insurance_product, class: InsurancePolicies::InsuranceProduct do
    name { "ABC plan" }
    hios_plan_id { "123456" }
    coverage_type { "health" }
    metal_level { "silver" }
    market_type { "individual" }
    plan_year { Date.today.year }
    ehb { BigDecimal(1) }

    insurance_provider
  end
end
