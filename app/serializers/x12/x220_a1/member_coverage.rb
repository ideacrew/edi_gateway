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

      def to_domain_parameters
        {}
      end
    end
  end
end