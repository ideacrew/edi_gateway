module InsurancePolicies
  module AcaIndividuals
    class CoverageHousehold
      include Mongoid::Document
      include Mongoid::Timestamps

      field :is_immediate_family, type: Boolean

      embeds_many :coverage_household_members,
                  class_name: "::InsurancePolicies::AcaIndividuals::CoverageHouseholdMember",
                  cascade_callbacks: true
    end
  end
end
