# frozen_string_literal: true

FactoryBot.define do
  factory :enrollments_tax_households, class: InsurancePolicies::AcaIndividuals::EnrollmentsTaxHouseholds do
    enrollment
    tax_household
    applied_aptc { 200.0 }
    household_benchmark_ehb_premium { 400.0 }
  end
end
