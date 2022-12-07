# frozen_string_literal: true

module InsurancePolicies
  module AcaIndividuals
    class IrsGroup
      include Mongoid::Document
      include Mongoid::Timestamps

      field :irs_group_id, type: String
      field :start_on, type: Date
      field :end_on, type: Date
      field :family_assigned_hbx_id, type: String

      embeds_many :insurance_agreements, class_name: "InsurancePolicies::AcaIndividuals::InsuranceAgreement",
                                         cascade_callbacks: true

      embeds_many :tax_household_groups, class_name: "InsurancePolicies::AcaIndividuals::TaxHouseholdGroup",
                  cascade_callbacks: true

      embeds_many :coverage_households, class_name: "InsurancePolicies::AcaIndividuals::CoverageHousehold",
                  cascade_callbacks: true

      scope :tax_household_groups_by_year, -> (year){ where("tax_household_groups.assistance_year" => year) }

      accepts_nested_attributes_for :insurance_agreements
      accepts_nested_attributes_for :tax_household_groups


      def irs_households_for_duration(year, max_month, policies)
        if tax_household_groups.empty?
          return insurance_agreements.first.tax_households.select{ |thh| thh.is_immediate_family == true }
        end

        thh_groups = tax_household_groups.select { |group| group.assistance_year == year }
        tax_households = thh_groups.map(&:tax_households).flatten!
        result = tax_households.select do |tax_household|
          had_coverage(tax_household, max_month, year, policies)
        end

        if result.present?
          result
        else
          insurance_agreements.first.tax_households.select{ |thh| thh.is_immediate_family == true }
        end
      end

      def had_coverage(tax_household, max_month, year, policies)
        thh_enrollments = InsurancePolicies::AcaIndividuals::TaxHouseholdEnrollment.where(tax_household_hbx_id: tax_household.tax_household_hbx_id)
        (1..max_month).each do |month|
          eg_ids = Policy.policies_for_month(month, year, policies).map(&:eg_id)

          if (thh_enrollments.map(&:enrollment_hbx_id) & eg_ids).any?
            return true
          end
        end
        false
      end
    end
  end
end
