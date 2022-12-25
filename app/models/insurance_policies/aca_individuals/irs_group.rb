# frozen_string_literal: true

module InsurancePolicies
  module AcaIndividuals
    class IrsGroup
      include Mongoid::Document
      include Mongoid::Timestamps
      include DomainModels::Domainable

      has_many :aca_individual_insurance_policies,
               class_name: 'InsurancePolicies::AcaIndividuals::InsurancePolicy',
               inverse_of: :irs_group

      # belongs_to :aca_individual_insurance_policies_irs_groups,
      #            class_name: 'InsurancePolicies::AcaIndividuals::InsurancePolicy'
      #
      #
      # has_many :aca_individual_insurance_policies_irs_groups
      # # accepts_nested_attributes_for :insurance_policy

      has_many :tax_household_groups, class_name: 'InsurancePolicies::AcaIndividuals::TaxHouseholdGroup',
               dependent: :destroy
      # accepts_nested_attributes_for :tax_household_group

      field :irs_group_id, type: String
      field :start_on, type: Date
      field :end_on, type: Date

      def irs_households_for_duration(year, max_month, policies)
        thh_groups = self.tax_household_groups.select { |group| group.assistance_year == 2022 }
        tax_households = thh_groups.map(&:tax_households).flatten!
        result = tax_households.select do |tax_household|
          next if tax_household.is_aqhp == false

          had_coverage(tax_household, max_month, year, policies)
        end

        if result.present?
          result
        else
          [self.tax_household_groups.where(is_aqhp: false).first.tax_households.last]
          # insurance_agreements.first.tax_households.select{ |thh| thh.is_immediate_family == true }
        end
      end


      def had_coverage(tax_household, max_month, year, policies)
        thh_enrollments = ::InsurancePolicies::AcaIndividuals::EnrollmentsTaxHouseholds.where(tax_household_id: tax_household.id)
        (1..max_month).each do |month|
          eg_ids = ::InsurancePolicies::AcaIndividuals::InsurancePolicy.enrollments_for_month(month, year, policies).map(&:hbx_id)

          if (thh_enrollments.flat_map(&:enrollment).map(&:hbx_id) & eg_ids).any?
            return true
          end
        end
        false
      end
    end
  end
end
