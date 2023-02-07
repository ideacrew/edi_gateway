# frozen_string_literal: true

FactoryBot.define do
  factory :enrolled_member, class: InsurancePolicies::AcaIndividuals::EnrolledMember do
    sequence(:ssn, 100000000, &:to_s)
    gender { 'male' }
  end
end
