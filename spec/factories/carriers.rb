# frozen_string_literal: true

FactoryBot.define do
  factory :carrier, class: Carrier do
    name {'ABC Carrier'}
    sequence(:hbx_carrier_id, &:to_s)
  end
end
