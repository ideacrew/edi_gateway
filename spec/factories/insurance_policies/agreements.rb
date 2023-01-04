# frozen_string_literal: true

FactoryBot.define do
  factory :insurance_agreement, class: InsurancePolicies::InsuranceAgreement do
    contract_holder
    insurance_provider
  end
end
