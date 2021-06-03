# frozen_string_literal: true

module X12
  module X220A1
    class TpaBrokerName
      include HappyMapper
      register_namespace 'x12', 'urn:x12:schemas:005:010:834A1A1:BenefitEnrollmentAndMaintenance'

      tag "N1_TPABrokerName_1000C"
      namespace 'x12'

      element :tpa_or_broker_name, String, tag: "N102__TPAOrBrokerName", namespace: "x12"
      element :identification_code_qualifier, String, tag: "N103__IdentificationCodeQualifier", namespace: "x12"
      element :tpa_or_broker_identifier, String, tag: "N104__TPAOrBrokerIdentificationCode", namespace: "x12"
    end
  end
end