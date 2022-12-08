# frozen_string_literal: true

module Enrollments
  # tax household member enrollment member
  class TaxHouseholdMemberEnrollmentMember
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :tax_household_enrollment,
                class_name: "Enrollments::TaxHouseholdEnrollment"

    field :person_hbx_id, type: String
    field :age_on_effective_date, type: Integer
    field :relationship_with_primary, type: String
    field :date_of_birth, type: Date

    belongs_to :person, class_name: "People::Person",
               inverse_of: :tax_household_member_enrollment_member
  end
end
