# frozen_string_literal: true

FactoryBot.define do
  # There is already a model and factory name with person, using the h36 development as name for this factory h36_person
  # TODO: Change to a meaningful name
  factory :people_person_name, class: People::PersonName do
    sequence(:first_name) { |n| "Test\##{n}" }
    sequence(:last_name) { |n| "Smith\##{n}" }
  end
end
