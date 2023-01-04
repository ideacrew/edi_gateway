# frozen_string_literal: true

FactoryBot.define do
  factory :plan, class: Plan do
    sequence(:name) { |n| "Super Plan A #{n}" }
    abbrev { 'SPA' }
    sequence(:hbx_plan_id)  { |n| "1234#{n}" }
    sequence(:hios_plan_id) { |n| "4321#{n}" }
    coverage_type { 'health' }
    metal_level { 'bronze' }
    market_type { 'individual' }
    ehb { 0.0 }
    carrier { FactoryBot.create(:carrier) }
    year { Date.today.year }
  end
end
