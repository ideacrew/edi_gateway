# frozen_string_literal: true

module X12
  module X220A1
    class PayerName
      include HappyMapper
      register_namespace 'x12', 'urn:x12:schemas:005:010:834A1A1:BenefitEnrollmentAndMaintenance'

      tag "N1_Payer_1000B"
      namespace 'x12'

      element :insurer_name, String, tag: "N102__InsurerName", namespace: "x12"
      element :identification_code_qualifier, String, tag: "N103__IdentificationCodeQualifier", namespace: "x12"
      element :insurer_identifier, String, tag: "N104__InsurerIdentificationCode", namespace: "x12"
    end
  end
end