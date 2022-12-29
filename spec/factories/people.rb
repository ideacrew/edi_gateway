# frozen_string_literal: true

FactoryBot.define do
  factory :person, class: People::Person do
    hbx_id { rand(10**6) }
  end
end
