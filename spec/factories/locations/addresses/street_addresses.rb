# frozen_string_literal: true

FactoryBot.define do
  factory :street_address, class: Locations::Addresses::StreetAddress do
    kind { 'home' }
    sequence(:address_1, 1111) { |n| "#{n} Awesome Street" }
    city_name { 'Awesome city' }
    state_abbreviation { 'DC' }
    zip_code { '20002' }
    county_name { "Awesome county" }
  end
end
