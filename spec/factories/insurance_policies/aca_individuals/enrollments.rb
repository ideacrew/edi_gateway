# frozen_string_literal: true

FactoryBot.define do
  factory :enrollment, class: InsurancePolicies::AcaIndividuals::Enrollment do
    insurance_policy

    sequence(:hbx_id)
    aasm_state { "coverage_selected" }
    total_premium_amount { Money.new(50000, "USD") }
    total_premium_adjustment_amount { Money.new(5000, "USD") }
    total_responsible_premium_amount { Money.new(45000, "USD") }
    effectuated_on { DateTime.now.beginning_of_month }
    start_on { DateTime.now.beginning_of_month }
  end
end
