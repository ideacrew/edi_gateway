# frozen_string_literal: true

FactoryBot.define do
  factory :address do
    address_type { 'home' }
    sequence(:address_1, 1111) { |n| "#{n} Awesome Street" }
    city { 'Washington' }
    state { 'DC' }
    zip { '20002' }
  end
end
