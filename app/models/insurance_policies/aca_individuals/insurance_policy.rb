# frozen_string_literal: true

module InsurancePolicies
  module AcaIndividuals
    # An instance of continuous coverage under a single insurance product
    class InsurancePolicy
      include Mongoid::Document
      include Mongoid::Timestamps
      include DomainModels::Domainable

      has_many :enrollments, class_name: 'InsurancePolicies::AcaIndividuals::Enrollment'

      accepts_nested_attributes_for :enrollments

      belongs_to :insurance_product, class_name: 'InsurancePolicies::InsuranceProduct', index: true

      belongs_to :insurance_agreement, class_name: 'InsurancePolicies::InsuranceAgreement',
                                       inverse_of: :insurance_policies, index: true

      belongs_to :irs_group, class_name: 'InsurancePolicies::AcaIndividuals::IrsGroup', optional: true,
                             index: true

      # TODO: NEED confirmation
      # belongs_to :plan_years_products, class_name: 'InsurancePolicies::AcaIndividuals::PlanYearsProducts'

      field :policy_id, type: String
      field :insurer_policy_id, type: String
      field :hbx_enrollment_ids, type: Array
      field :marketplace_segment_id, type: String
      field :start_on, type: Date
      field :end_on, type: Date
      field :aasm_state, type: String
      field :carrier_policy_id, type: String
      field :term_for_np, type: Boolean, default: false

      # indexes
      index({ "policy_id" => 1 })
      index({ "hbx_enrollment_ids" => 1 })
      index({ "aasm_state" => 1 })
      index({ "start_on" => 1 })
      index({ "end_on" => 1 })

      def policy_end_on
        end_on.present? ? end_on : start_on.end_of_year
      end

      def enrollments_for_month(calendar_month, calendar_year)
        self.class.enrollments_for_month(calendar_month, calendar_year, [self])
      end

      def is_effectuated?(month, year)
        end_of_month = Date.new(year, month, 1).end_of_month
        return unless start_on < end_of_month

        start_date = start_on
        end_date = end_on.present? ? end_on : start_date.end_of_year
        coverage_end_month = end_date.month
        coverage_end_month = 12 if year != end_date.year
        (start_date.month..coverage_end_month).include?(month)
      end

      def enrollments_tax_households(enrs_for_month)
        ::InsurancePolicies::AcaIndividuals::EnrollmentsTaxHouseholds
          .where(:enrollment_id.in => enrs_for_month.pluck(:id))
      end

      def fetch_aptc_tax_credit(enrs_for_month, tax_household = nil)
        applied_aptc = enrs_for_month.map(&:total_premium_adjustment_amount).max
        return format('%.2f', (applied_aptc || 0.0)) if tax_household.blank?

        tax_credit = fetch_aptc_from_tax_household(tax_household, enrs_for_month, applied_aptc)
        format('%.2f', tax_credit)
      end

      def fetch_aptc_from_tax_household(tax_household, enrs_for_month, applied_aptc)
        tax_filer = tax_household.primary
        enr_thhs = enrollments_tax_households(enrs_for_month)
        enr_thh_for_month = enr_thhs.detect do |enr_thh|
          enr_thh.tax_household.tax_household_members.map(&:person_id).include?(tax_filer.person_id)
        end

        return applied_aptc || 0.0 if enr_thh_for_month.blank?

        enr_thh_for_month.applied_aptc.to_f
      end

      def fetch_enrollments_tax_households(enrs_for_month)
        ::InsurancePolicies::AcaIndividuals::EnrollmentsTaxHouseholds
          .where(:enrollment_id.in => enrs_for_month.pluck(:id))
      end

      def fetch_slcsp_premium(enrs_for_month, calendar_month, tax_household = nil)
        return format('%.2f', (0.0)) if term_for_np && policy_end_on.month == calendar_month

        enr_thhs = fetch_enrollments_tax_households(enrs_for_month)
        slcsp_premium = enr_thhs.map(&:household_benchmark_ehb_premium).compact.sum
        return format('%.2f', (slcsp_premium || 0.0)) if tax_household.blank?

        slcsp = fetch_slcsp_from_tax_household(tax_household, enr_thhs)
        format('%.2f', slcsp)
      end

      def fetch_slcsp_from_tax_household(tax_household, enr_thhs)
        tax_filer = tax_household.primary
        enr_thh_for_month = enr_thhs.detect do |enr_thh|
          enr_thh.tax_household.tax_household_members.map(&:person_id).include?(tax_filer.person_id)
        end

        return 0.0 if enr_thh_for_month.blank?

        enr_thh_for_month.household_benchmark_ehb_premium.to_f
      end

      # rubocop:disable Metrics/AbcSize
      def self.enrollments_for_month(month, year, policies)
        policies.flat_map(&:enrollments).select do |enrollment|
          next if enrollment.aasm_state == "coverage_canceled"

          start_date = enrollment.effectuated_on
          end_date = enrollment.end_on.present? ? enrollment.end_on : start_date.end_of_year
          end_of_month = Date.new(year, month, 1).end_of_month
          coverage_end_month = end_date.month
          coverage_end_month = 12 if year != end_date.year
          next unless start_date < end_of_month

          (start_date.month..coverage_end_month).include?(month)
        end
      end
      # rubocop:enable Metrics/AbcSize
    end
  end
end
