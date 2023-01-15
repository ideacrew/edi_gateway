# frozen_string_literal: true

FactoryBot.define do
  factory :contact_email, class: Contacts::Email do
    kind { 'home' }
    sequence(:address) { |n| "example#{n}@example.com" }
  end
end
