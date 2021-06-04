# frozen_string_literal: true

module X12
  module X220A1
    # Supplemental identifiers under loop 2000.
    class MemberSupplementalIdentifier
      include HappyMapper
      register_namespace 'x12', 'urn:x12:schemas:005:010:834A1A1:BenefitEnrollmentAndMaintenance'

      tag "REF_MemberSupplementalIdentifier_2000"
      namespace 'x12'

      element :identification_qualifier, String, tag: "REF01__ReferenceIdentificationQualifier", namespace: "x12"
      element :supplemental_identifier, String, tag: "REF02__MemberSupplementalIdentifier", namespace: "x12"

      def to_domain_parameters
        {
          reference_identification_qualifier: identification_qualifier,
          reference_identification: supplemental_identifier
        }
      end
    end
  end
end