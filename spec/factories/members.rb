# frozen_string_literal: true

FactoryBot.define do
  factory :member, class: Member do
    sequence(:hbx_member_id, &:to_s)
    gender { 'female' }
    sequence(:ssn, 100000000, &:to_s)
  end
end
