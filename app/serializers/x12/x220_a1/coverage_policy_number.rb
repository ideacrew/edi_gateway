# frozen_string_literal: true

module X12
  module X220A1
    # Loop 2300 policy numbers - REF.
    class CoveragePolicyNumber
      include HappyMapper
      register_namespace 'x12', 'urn:x12:schemas:005:010:834A1A1:BenefitEnrollmentAndMaintenance'

      tag "REF_HealthCoveragePolicyNumber_2300"
      namespace 'x12'

      element :identification_qualifier, String, tag: "REF01__ReferenceIdentificationQualifier", namespace: "x12"
      element :reference_identification, String, tag: "REF02__MemberGroupOrPolicyNumber", namespace: "x12"
    end
  end
end