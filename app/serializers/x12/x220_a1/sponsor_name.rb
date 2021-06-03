# frozen_string_literal: true

module X12
  module X220A1
    class SponsorName
      include HappyMapper
      register_namespace 'x12', 'urn:x12:schemas:005:010:834A1A1:BenefitEnrollmentAndMaintenance'

      tag "N1_SponsorName_1000A"
      namespace 'x12'

      element :plan_sponsor_name, String, tag: "N102__PlanSponsorName", namespace: "x12"
      element :identification_code_qualifier, String, tag: "N103__IdentificationCodeQualifier", namespace: "x12"
      element :sponsor_identifier, String, tag: "N104__SponsorIdentifier", namespace: "x12"
    end
  end
end