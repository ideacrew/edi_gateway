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

      def enrollment_for_month(calendar_year, calendar_month)
        self.class.enrollments_for_month(calendar_year, calendar_month, [self])&.last
      end

      # def covered_enrollees_as_of(month, year)
      #   month_begin = Date.new(year, month, 1)
      #   month_end = month_begin.end_of_month
      #   effectuated_enrollments = enrollments.select do |enrollment|
      #     next if enrollment.aasm_state == "coverage_canceled"
      #     enrollment
      #   end
      #
      #   enrollees = effectuated_enrollments.flat_map(&:subscriber) + effectuated_enrollments.flat_map(&:dependents)
      #
      #   enrollees.compact.flatten.select do |enrollee|
      #     enrollment = enrollee.aca_individuals_enrollment
      #     enrollee_coverage_end = enrollment.end_on.present? ? enrollee.end_on : enrollee.start_on.end_of_year
      #     (enrollee.start_on <= month_end) && (enrollee_coverage_end >= month_begin)
      #   end
      # end

      def self.enrollments_for_month(month, year, policies)
        effectuated_enrollments = policies.flat_map(&:enrollments).select {|enrollment| enrollment.aasm_state != "coverage_canceled"}
        effectuated_enrollments.select do |enrollment|
          start_date = enrollment.effectuated_on
          end_date = enrollment.end_on.present? ? enrollment.end_on : start_date.end_of_year
          end_of_month = Date.new(year, month, 1).end_of_month
          coverage_end_month = end_date.month
          coverage_end_month = 12 if year != end_date.year
          next unless start_date < end_of_month

          (start_date.month..coverage_end_month).include?(month)
        end
      end
    end
  end
end
