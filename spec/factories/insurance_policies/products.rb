# frozen_string_literal: true

FactoryBot.define do
  factory :insurance_product, class: InsurancePolicies::InsuranceProduct do
    insurance_provider

  end
end
