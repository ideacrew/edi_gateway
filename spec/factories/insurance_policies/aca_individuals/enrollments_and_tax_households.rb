# frozen_string_literal: true

FactoryBot.define do
  factory :enrollments_tax_households, class: InsurancePolicies::AcaIndividuals::EnrollmentsTaxHouseholds do
    enrollment
    tax_household
  end
end
