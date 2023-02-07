# frozen_string_literal: true

FactoryBot.define do
  factory :tax_household_group, class: InsurancePolicies::AcaIndividuals::TaxHouseholdGroup do
    irs_group
  end
end
