# frozen_string_literal: true

FactoryBot.define do
  factory :person, class: Person do
    sequence(:name_first) { |n| "Test\##{n}" }
    sequence(:name_last) { |n| "Smith\##{n}" }

    transient do
      dob { Date.today - 35.years }
    end

    transient do
      sequence(:hbx_member_id) { |n| "1234#{n}" }
    end

    after(:create) do |p, evaluator|
      create_list(:member,  2, person: p, dob: evaluator.dob, hbx_member_id: evaluator.hbx_member_id)
      create_list(:address, 2, person: p)
      create_list(:phone,   2, person: p)
      create_list(:email,   2, person: p)
      p.authority_member_id = p.members.first.hbx_member_id
    end
  end
end
