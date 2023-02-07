# frozen_string_literal: true

FactoryBot.define do
  factory :contact_phone, class: Contacts::Phone do
    kind { 'home' }
    sequence(:number, 1111111111, &:to_s)
    sequence(:extension, &:to_s)
    primary { true }
  end
end
