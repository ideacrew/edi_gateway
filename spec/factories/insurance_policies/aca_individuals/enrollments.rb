# frozen_string_literal: true

FactoryBot.define do
  factory :enrollment, class: InsurancePolicies::AcaIndividuals::Enrollment do
    insurance_policy

    hbx_id { rand(10**6) }
    aasm_state { "coverage_selected" }
    total_premium_amount { 0.0 }
    total_premium_adjustment_amount { 0.0 }
    total_responsible_premium_amount { 0.0 }
    effectuated_on { DateTime.now.beginning_of_month }
    start_on { DateTime.now.beginning_of_month }
  end
end
