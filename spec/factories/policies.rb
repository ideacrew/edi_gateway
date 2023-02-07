# frozen_string_literal: true

FactoryBot.define do
  factory :policy, class: Policy do
    plan

    trait :with_enrollee do
      after(:create) do |p, _evaluator|
        create_list(:enrollee, 1, policy: p)
      end
    end
  end
end
