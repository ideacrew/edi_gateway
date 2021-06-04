# frozen_string_literal: true

module X12
  module X220A1
    # Member coverage - loop 2300.
    class MemberCoverage
      include HappyMapper
      register_namespace 'x12', 'urn:x12:schemas:005:010:834A1A1:BenefitEnrollmentAndMaintenance'

      tag "Loop_2300"
      namespace 'x12'

      has_one :health_coverage_segment, HealthCoverageSegment
      has_many :coverage_dates, CoverageDate
      has_many :coverage_policy_numbers, CoveragePolicyNumber

      delegate :maintenance_type_code, to: :health_coverage_segment, allow_nil: true
      delegate :insurance_line_code, to: :health_coverage_segment, allow_nil: true
      delegate :coverage_level_code, to: :health_coverage_segment, allow_nil: true

      # rubocop:disable Style/IfUnlessModifier
      def to_domain_parameters
        optional_params = {}
        unless coverage_level_code.blank?
          optional_params[:coverage_level_code] = coverage_level_code
        end
        {
          maintenance_type_code: maintenance_type_code,
          insurance_line_code: insurance_line_code,
          coverage_policy_numbers: coverage_policy_numbers.map(&:to_domain_parameters)
        }.merge(optional_params).merge(date_parameters)
      end
      # rubocop:enable Style/IfUnlessModifier

      protected

      # rubocop:disable Style/IfUnlessModifier
      def date_parameters
        dates, ranges = coverage_dates.partition(&:is_previous_coverage_range?)
        optional_date_ranges = {}
        if ranges.any?
          optional_date_ranges[:previous_coverage_periods] = ranges.map(&:to_domain_parameters)
        end
        {
          coverage_dates: dates.map(&:to_domain_parameters)
        }.merge(optional_date_ranges)
      end
      # rubocop:enable Style/IfUnlessModifier
    end
  end
end