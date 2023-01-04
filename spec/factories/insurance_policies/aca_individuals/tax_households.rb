# frozen_string_literal: true

FactoryBot.define do
  factory :tax_household, class: InsurancePolicies::AcaIndividuals::TaxHousehold do
    tax_household_group
    sequence(:hbx_id)
    is_eligibility_determined { true }
    allocated_aptc { 0.0 }
    max_aptc { 0.0 }
    yearly_expected_contribution { 0.0 }
    is_aqhp { true }
    start_on { DateTime.now.beginning_of_month }
  end
end
