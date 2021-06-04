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

      # rubocop:disable Naming/PredicateName
      def is_previous_coverage_range?
        format_qualifier == "RD8"
      end
      # rubocop:enable Naming/PredicateName

      def to_domain_parameters
        if is_previous_coverage_range?
          date_range = parse_date_range
          {
            start_date: date_range[:start],
            end_date: date_range[:end]
          }
        else
          {
            date_qualifier: date_qualifier,
            date: parse_date(date)
          }
        end
      end

      protected

      def parse_date_range
        return {} if date.blank?
        first, second = date.split("-")
        {
          start: parse_date(first),
          end: parse_date(second)
        }
      end

      def parse_date(the_date)
        return nil if the_date.blank?
        Date.strptime(the_date, "%Y%m%d")
      end
    end
  end
end