# frozen_string_literal: true

module InsurancePolicies
  module AcaIndividuals
    # Every tax household enrollment  will have many tax household member enrollment members
    class EnrolledMembersTaxHouseholdMembers
      include Mongoid::Document
      include Mongoid::Timestamps

      field :person_hbx_id, type: String
      field :age_on_effective_date, type: Integer
      field :relationship_with_primary, type: String
      field :date_of_birth, type: Date

      belongs_to :enrollments_tax_households,
                 class_name: "::InsurancePolicies::AcaIndividuals::EnrollmentsTaxHouseholds", index: true

      belongs_to :person, class_name: 'People::Person', index: true
      accepts_nested_attributes_for :person

      # indexes
      index({ person_hbx_id: 1 })
      index({ relationship_with_primary: 1 })
    end
  end
end
