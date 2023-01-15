# frozen_string_literal: true

FactoryBot.define do
  factory :insurance_agreement, class: InsurancePolicies::InsuranceAgreement do
    insurance_provider
  end
end
