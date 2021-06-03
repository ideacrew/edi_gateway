# frozen_string_literal: true

module X12
  module X220A1
    # Member level dates under Loop 2000.
    class MemberLevelDate
      include HappyMapper
      register_namespace 'x12', 'urn:x12:schemas:005:010:834A1A1:BenefitEnrollmentAndMaintenance'

      tag "DTP_MemberLevelDates_2000"
      namespace 'x12'

      element :date_qualifier, String, tag: "DTP01__DateTimeQualifier", namespace: "x12"
      element :format_qualifier, String, tag: "DTP02__DateTimePeriodFormatQualifier", namespace: "x12"
      element :date, String, tag: "DTP03__StatusInformationEffectiveDate", namespace: "x12"
    end
  end
end