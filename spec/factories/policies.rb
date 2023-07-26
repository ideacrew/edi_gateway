# frozen_string_literal: true

FactoryBot.define do
  factory :policy, class: Policy do
    plan
    sequence(:id) { |n| "1234#{n}" }
    sequence(:eg_id) { |n| "4321#{n}" }
    after(:create) do |p, _evaluator|
      create_list(:enrollee, 2, policy: p)
    end

    trait :with_enrollee do
      after(:create) do |p, _evaluator|
        create_list(:enrollee, 1, policy: p)
      end
    end
  end
end
