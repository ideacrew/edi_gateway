# frozen_string_literal: true

FactoryBot.define do
  factory :address do
    address_type { 'home' }
    sequence(:address_1, 1111) { |n| "#{n} Awesome Street" }
    sequence(:address_2, 111, &:to_s)
    city { 'Washington' }
    state { 'DC' }
    zip { '20002' }
  end
end
