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
      field :marketplace_segment_id, type: String
      field :start_on, type: Date
      field :end_on, type: Date
      field :aasm_state, type: String
      field :carrier_policy_id, type: String
      field :term_for_np, type: Boolean, default: false

      # indexes
      index({ "policy_id" => 1 })
      index({ "aasm_state" => 1 })
      index({ "start_on" => 1 })
      index({ "end_on" => 1 })

      def policy_end_on
        end_on.present? ? end_on : start_on.end_of_year
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

      # Effectuated Aptc Tax Households with Unique member composition
      # Policy:
      #   HbxEnrollment1:
      #     A, B
      #     both are on same THH1
      #   HbxEnrollment2:
      #     A, B
      #     both are on different THH2,THH3
      #   HbxEnrollment3:
      #     A, B
      #     both are on same THH4
      # Result:
      #   [THH1, THH2, THH3]

      # rubocop:disable Metrics/AbcSize
      def effectuated_aptc_tax_households_with_unique_composition
        enrollments_tax_households = enrollments_tax_households(effectuated_enrollments)
        aqhp_enr_thhs = fetch_aqhp_enrollments_tax_households(enrollments_tax_households)
        uqhp_enr_thhs = fetch_uqhp_enrollments_tax_households(enrollments_tax_households)

        return [uqhp_enr_thhs&.last&.tax_household] || irs_group.uqhp_tax_households(start_on.year) if aqhp_enr_thhs.blank?

        tax_households = aqhp_enr_thhs.flat_map(&:tax_household).uniq do |tax_household|
          tax_household.primary&.person_id
        end

        thh_with_members_info = fetch_aqhp_thh_member_info(tax_households)
        thh_with_members_info.uniq(&:last).to_h.keys.presence || irs_group.uqhp_tax_households(start_on.year)
      end
      # rubocop:enable Metrics/AbcSize

      def fetch_aqhp_thh_member_info(tax_households)
        tax_households.each_with_object([]) do |thh, thh_info|
          thh_info << [thh, thh.tax_household_members.map(&:person).map(&:hbx_id)]
        end
      end

      def fetch_aqhp_enrollments_tax_households(enrollments_tax_households)
        enrollments_tax_households.select do |enr_thh|
          enr_thh.tax_household.is_aqhp
        end
      end

      def fetch_uqhp_enrollments_tax_households(enrollments_tax_households)
        enrollments_tax_households.reject do |enr_thh|
          enr_thh.tax_household.is_aqhp
        end
      end

      def valid_enrollment_tax_household?(enr_thh, tax_household)
        tax_filer_id = tax_household.primary&.person_id || tax_household.tax_household_members.first.person_id

        enr_thh_tax_filer_id =
          enr_thh.tax_household.primary&.person_id || enr_thh.tax_household.tax_household_members.first.person_id

        enr_thh_tax_filer_id == tax_filer_id
      end

      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def applied_aptc_amount_for(enrollments_for_month, calender_month, tax_household)
        en_tax_households = enrollments_tax_households(enrollments_for_month)
        enr_thhs_for_month = en_tax_households.select do |enr_thh|
          valid_enrollment_tax_household?(enr_thh, tax_household) && enr_thh.tax_household.is_aqhp
        end

        return format('%<val>.2f', val: 0.0) if enr_thhs_for_month.none? do |en_tax_household|
                                                  en_tax_household.tax_household.is_aqhp == true
                                                end

        calender_month_begin = Date.new(start_on.year, calender_month, 1)
        calender_month_end = calender_month_begin.end_of_month
        end_of_year = start_on.end_of_year
        calender_month_days = (calender_month_begin..calender_month_end).count

        total_aptc_amount = enr_thhs_for_month.sum do |en_tax_household|
          enrollment = en_tax_household.enrollment

          en_month_start_on = [enrollment.start_on, calender_month_begin].max
          en_month_end_on   = [enrollment.end_on || end_of_year, calender_month_end].min
          en_coverage_days  = (en_month_start_on..en_month_end_on).count

          if calender_month_days == en_coverage_days
            en_tax_household.applied_aptc
          else
            (en_tax_household.applied_aptc.to_f / calender_month_days) * en_coverage_days
          end
        end

        format('%.2f', total_aptc_amount)
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

      def fetch_aptc_tax_credit(enrs_for_month, tax_household = nil)
        applied_aptc = enrs_for_month.map(&:total_premium_adjustment_amount).max
        return format('%.2f', (applied_aptc || 0.0)) if tax_household.blank?

        tax_credit = fetch_aptc_from_tax_household(tax_household, enrs_for_month, applied_aptc)
        format('%.2f', tax_credit)
      end

      def fetch_tax_filer(tax_household)
        return tax_household.primary if tax_household.is_aqhp

        tax_household.tax_household_members.detect(&:is_subscriber)
      end

      def fetch_aptc_from_tax_household(tax_household, enrs_for_month, applied_aptc)
        tax_filer = fetch_tax_filer(tax_household)
        enr_thhs = enrollments_tax_households(enrs_for_month)
        enr_thh_for_month = enr_thhs.detect do |enr_thh|
          enr_thh.tax_household.tax_household_members.map(&:person_id).include?(tax_filer&.person_id)
        end

        return applied_aptc || 0.0 if enr_thh_for_month.blank?

        enr_thh_for_month.applied_aptc.to_f
      end

      def fetch_enrollments_tax_households(enrs_for_month)
        ::InsurancePolicies::AcaIndividuals::EnrollmentsTaxHouseholds
          .where(:enrollment_id.in => enrs_for_month.pluck(:id))
      end

      def fetch_slcsp_premium(enrs_for_month, calendar_month, tax_household = nil)
        return format('%.2f', 0.0) if term_for_np && policy_end_on.month == calendar_month

        enr_thhs = fetch_enrollments_tax_households(enrs_for_month)
        slcsp_premium = enr_thhs.map(&:household_benchmark_ehb_premium).compact.sum
        return format('%.2f', (slcsp_premium || 0.0)) if tax_household.blank?

        slcsp = fetch_slcsp_from_tax_household(tax_household, enr_thhs)
        format('%.2f', slcsp)
      end

      def fetch_slcsp_from_tax_household(tax_household, enr_thhs)
        return 0.0 unless enr_thhs.any? { |enr_thh| enr_thh.tax_household.is_aqhp == true }

        tax_filer = fetch_tax_filer(tax_household)
        enr_thh_for_month = enr_thhs.detect do |enr_thh|
          enr_thh.tax_household.is_aqhp &&
            enr_thh.tax_household.tax_household_members.map(&:person_id).include?(tax_filer&.person_id)
        end

        return 0.0 if enr_thh_for_month.blank?

        enr_thh_for_month.household_benchmark_ehb_premium.to_f
      end

      def effectuated_enrollments
        @effectuated_enrollments ||= if aasm_state == "canceled"
                                       enrollments
                                     else
                                       enrollments.reject { |enr| enr.aasm_state == "coverage_canceled" }
                                     end
      end

      def fetch_member_start_on(enrolled_member_hbx_id)
        enrollments = effectuated_enrollments.select do |enrollment|
          enrolled_members = [enrollment.subscriber] + enrollment.dependents
          enrolled_members.any? { |member| member.person.hbx_id == enrolled_member_hbx_id }
        end
        enrollments.pluck(:start_on).min
      end

      def fetch_enrolled_member_end_date(enrolled_member)
        enrolled_member_enrollments = effectuated_enrollments.select do |enrollment|
          members = [enrollment.subscriber] + enrollment.dependents
          members.map(&:person_id).include?(enrolled_member.person_id)
        end
        enrolled_member_enrollments.map(&:enrollment_end_on).max
      end

      def enrollments_for_month(month, year)
        enrollments.select do |enrollment|
          next if enrollment.aasm_state == "coverage_canceled"

          start_date = enrollment.effectuated_on
          end_date = enrollment.end_on.present? ? enrollment.end_on : start_date.end_of_year
          end_of_month = Date.new(year, month, 1).end_of_month
          coverage_end_month = end_date.month
          coverage_end_month = 12 if year != end_date.year
          next unless start_date < end_of_month

          (start_date.month..coverage_end_month).include?(month)
        end.compact
      end
    end
  end
end
