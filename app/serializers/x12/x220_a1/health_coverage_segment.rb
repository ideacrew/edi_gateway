# frozen_string_literal: true

module X12
  module X220A1
    # Loop 2300 - HD segment.
    class HealthCoverageSegment
      include HappyMapper
      register_namespace 'x12', 'urn:x12:schemas:005:010:834A1A1:BenefitEnrollmentAndMaintenance'

      tag "HD_HealthCoverage_2300"
      namespace 'x12'

      element :maintenance_type_code, String, tag: "HD01__MaintenanceTypeCode", namespace: "x12"
      element :insurance_line_code, String, tag: "HD03__InsuranceLineCode", namespace: "x12"
      element :coverage_level_code, String, tag: "HD04__PlanCoverageDescription", namespace: "x12"
    end
  end
end