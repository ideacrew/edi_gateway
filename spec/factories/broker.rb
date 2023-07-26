# frozen_string_literal: true

FactoryBot.define do
  factory :broker do
    name_pfx { 'Mr' }
    name_first { 'John' }
    name_middle { 'X' }
    sequence(:name_last) { |n| "Smith\##{n}" }
    name_sfx { 'Jr' }
    sequence(:npn, &:to_s)
    b_type { 'broker' }
  end
end
