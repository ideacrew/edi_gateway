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

      has_many :tax_household_groups,
               class_name: 'InsurancePolicies::AcaIndividuals::TaxHouseholdGroup',
               dependent: :destroy

      field :irs_group_id, type: String
      field :family_hbx_assigned_id, type: String
      field :start_on, type: Date
      field :end_on, type: Date

      # indexes
      index({ irs_group_id: 1 })
      index({ family_hbx_assigned_id: 1 })

      def insurance_agreements
        aca_individual_insurance_policies&.map(&:insurance_agreement)&.uniq
      end

      def active_tax_household_group(calendar_year)
        tax_household_groups.where(end_on: Date.new(calendar_year, 12, 31), assistance_year: calendar_year)&.first ||
          tax_household_groups.where(end_on: nil, assistance_year: calendar_year)&.first
      end

      def active_thhs_with_tax_filer(calendar_year)
        active_tax_household_group(calendar_year)
          &.tax_households
          &.select do |thh|
            if thh.tax_household_members.where(tax_filer_status: 'tax_filer').present? ||
                 thh.tax_household_members.where(is_medicaid_chip_eligible: true).present?
              thh
            end
          end
      end

      def uqhp_tax_households(calendar_year)
        uqhp_thh_group = tax_household_groups.where(is_aqhp: false)
        return [tax_household_groups&.all&.last&.tax_households].flatten if uqhp_thh_group.blank?

        [tax_household_groups.where(is_aqhp: false, assistance_year: calendar_year).first.tax_households.last]
      end

      def active_tax_households(calendar_year)
        result = active_thhs_with_tax_filer(calendar_year)
        return result.to_a if result.present?

        uqhp_tax_households(calendar_year)
      end

      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/CyclomaticComplexity
      def active_thh_for_month(month, year)
        tax_household_groups
          .flat_map(&:tax_households)
          .detect do |thh|
            next if thh.start_on == thh.end_on
            next if thh.tax_household_group.is_aqhp == false

            end_of_month = Date.new(year, month, 1).end_of_month
            next unless thh.start_on < end_of_month

            start_date = thh.start_on
            end_date = thh.end_on.present? ? thh.end_on.month : start_date.end_of_year
            coverage_end_month = end_date.month
            coverage_end_month = 12 if year != end_date.year
            (start_date.month..coverage_end_month).include?(month)
          end
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/CyclomaticComplexity
    end
  end
end
