# frozen_string_literal: true

module X12
  module X220A1
    # Loop 2300 coverage dates - DTP.
    class CoverageDate
      include HappyMapper
      register_namespace 'x12', 'urn:x12:schemas:005:010:834A1A1:BenefitEnrollmentAndMaintenance'

      tag "DTP_HealthCoverageDates_2300"
      namespace 'x12'

      element :date_qualifier, String, tag: "DTP01__DateTimeQualifier", namespace: "x12"
      element :format_qualifier, String, tag: "DTP02__DateTimePeriodFormatQualifier", namespace: "x12"
      element :date, String, tag: "DTP03__CoveragePeriod", namespace: "x12"
    end
  end
end