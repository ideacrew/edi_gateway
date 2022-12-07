# frozen_string_literal: true

module InsurancePolicies
  module AcaIndividuals
    # Every IRS Group will have many tax household groups
    class TaxHouseholdEnrollment
      include Mongoid::Document
      include Mongoid::Timestamps

      field :tax_household_hbx_id, type: String
      field :enrollment_hbx_id, type: String
      field :household_benchmark_ehb_premium, type: Money
      field :health_product_hios_id, type: String
      field :dental_product_hios_id, type: String
      field :household_health_benchmark_ehb_premium, type: Money
      field :household_dental_benchmark_ehb_premium, type: Money
      field :applied_aptc, type: Money
      field :available_max_aptc, type: Money

      embeds_many :tax_household_members_enrollment_members,
                  class_name: "::InsurancePolicies::AcaIndividuals::TaxHouseholdMemberEnrollmentMember",
                  cascade_callbacks: true

      accepts_nested_attributes_for :tax_household_members_enrollment_members

      def self.thh_enrollments_for(tax_household)
        InsurancePolicies::AcaIndividuals::TaxHouseholdEnrollment.where(tax_household_hbx_id: tax_household.tax_household_hbx_id)
      end
    end
  end
end
