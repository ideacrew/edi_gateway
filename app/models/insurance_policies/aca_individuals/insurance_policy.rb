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

      belongs_to :insurance_product, class_name: 'InsurancePolicies::InsuranceProduct'

      belongs_to :insurance_agreement, class_name: 'InsurancePolicies::InsuranceAgreement',
                                       inverse_of: :insurance_policies

      belongs_to :irs_group, class_name: 'InsurancePolicies::AcaIndividuals::IrsGroup', optional: true

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
        end_date = end_on.present? ? end_on.month : start_date.end_of_year
        coverage_end_month = end_date.month
        coverage_end_month = 12 if year != end_date.year
        (start_date.month..coverage_end_month).include?(month)
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
