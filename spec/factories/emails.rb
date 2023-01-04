# frozen_string_literal: true

FactoryBot.define do
  factory :email do
    email_type { 'home' }
    sequence(:email_address) { |n| "example#{n}@example.com" }
  end
end
