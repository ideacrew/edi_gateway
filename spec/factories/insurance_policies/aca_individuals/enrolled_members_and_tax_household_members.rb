# frozen_string_literal: true

FactoryBot.define do
  factory :enrolled_members_tax_household_members, class: InsurancePolicies::AcaIndividuals::EnrolledMembersTaxHouseholdMembers do
    person { FactoryBot.create(:people_person) }
    enrollments_tax_households

    person_hbx_id { person.hbx_id }
  end
end
