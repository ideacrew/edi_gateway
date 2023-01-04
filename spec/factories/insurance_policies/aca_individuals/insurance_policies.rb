# frozen_string_literal: true

FactoryBot.define do
  factory :insurance_policy, class: InsurancePolicies::AcaIndividuals::InsurancePolicy do
    insurance_product
    insurance_agreement
    irs_group
  end
end
