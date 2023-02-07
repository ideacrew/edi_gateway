# frozen_string_literal: true

FactoryBot.define do
  factory :premium_schedule, class: InsurancePolicies::PremiumSchedule do
    premium_amount { 500.0 }
    benchmark_ehb_premium_amount { 500.0 }
    next_due_on { nil }
  end
end
