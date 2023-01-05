# frozen_string_literal: true

FactoryBot.define do
  # There is already a model and factory name with person, using the h36 development as name for this factory h36_person
  # TODO: Change to a meaningful name
  factory :people_person, class: People::Person do
    sequence(:hbx_id)
  end
end
