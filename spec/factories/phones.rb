# frozen_string_literal: true

FactoryBot.define do
  factory :phone do
    phone_type { 'home' }
    sequence(:phone_number, 1111111111, &:to_s)
    sequence(:extension, &:to_s)
    primary { true }
  end
end
