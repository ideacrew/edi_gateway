# frozen_string_literal: true

module InsurancePolicies
  module AcaIndividuals
    # Every tax household enrollment  will have many tax household member enrollment members
    class TaxHouseholdMemberEnrollmentMember
      include Mongoid::Document
      include Mongoid::Timestamps

      field :person_hbx_id, type: String
      field :age_on_effective_date, type: Integer
      field :relationship_with_primary, type: String
      field :date_of_birth, type: Date

      embedded_in :tax_household_enrollment,
                  class_name: "::InsurancePolicies::AcaIndividuals::TaxHouseholdEnrollment"

      belongs_to :member, class_name: "::InsurancePolicies::AcaIndividuals::Member",
                 inverse_of: :insurance_provider
    end
  end
end
