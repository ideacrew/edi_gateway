module InsurancePolicies
  module AcaIndividuals
    class CoverageHouseholdMember
      include Mongoid::Document
      include Mongoid::Timestamps

      field :person_hbx_id, type: String
      field :is_subscriber, type: Boolean, default: false
      field :relation_with_primary, type: String

      embeds_many :coverage_household_members,
                  class_name: "::InsurancePolicies::AcaIndividuals::CoverageHouseholdMember",
                  cascade_callbacks: true

      embedded_in :coverage_household, class_name: "::InsurancePolicies::AcaIndividuals::CoverageHousehold"

      belongs_to :member, class_name: "::InsurancePolicies::AcaIndividuals::Member",
                 inverse_of: :coverage_household_member
    end
  end
end
