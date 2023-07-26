# frozen_string_literal: true

FactoryBot.define do
  factory :policy, class: Policy do
    sequence(:eg_id, &:to_s)
    pre_amt_tot { '666.66' }
    tot_res_amt { '111.11' }
    tot_emp_res_amt { '222.22' }
    carrier_to_bill { true }
    allocated_aptc { '1.11' }
    elected_aptc { '2.22' }
    applied_aptc { '3.33' }
    broker
    plan
    sequence(:id) { |n| "1234#{n}" }
    sequence(:eg_id) { |n| "4321#{n}" }
    carrier_specific_plan_id { 'rspec-mock' }
    rating_area { "100" }
    composite_rating_tier { 'rspec-mock' }
    kind { 'individual' }
    after(:create) do |p, _evaluator|
      create_list(:enrollee, 2, policy: p)
    end

    trait :with_enrollee do
      after(:create) do |p, _evaluator|
        create_list(:enrollee, 1, policy: p)
      end
    end

    transient do
      coverage_start { Date.new(2014, 1, 2) }
      coverage_end   { Date.new(2014, 3, 4) }
    end
  end
end
