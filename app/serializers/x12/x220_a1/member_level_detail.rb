# frozen_string_literal: true

module X12
  module X220A1
    # Details for the member, found in the INS segment.
    class MemberLevelDetail
      include HappyMapper
      register_namespace 'x12', 'urn:x12:schemas:005:010:834A1A1:BenefitEnrollmentAndMaintenance'

      tag "INS_MemberLevelDetail_2000"
      namespace 'x12'

      element :member_indicator, String, tag: "INS01__MemberIndicator", namespace: "x12"
      element :maintenance_type_code, String, tag: "INS03__MaintenanceTypeCode", namespace: "x12"
      element :maintenance_reason_code, String, tag: "INS04__MaintenanceReasonCode", namespace: "x12"

      def subscriber_indicator
        member_indicator == "Y"
      end
    end
  end
end