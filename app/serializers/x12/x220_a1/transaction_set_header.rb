# frozen_string_literal: true

module X12
  module X220A1
    class TransactionSetHeader
      include HappyMapper
      register_namespace 'x12', 'urn:x12:schemas:005:010:834A1A1:BenefitEnrollmentAndMaintenance'

      tag "ST_TransactionSetHeader"
      namespace 'x12'

      element :transaction_set_identifier_code, String, tag: "ST01__TransactionSetIdentifierCode", namespace: "x12"
      element :transaction_set_control_number, String, tag: "ST02__TransactionSetControlNumber", namespace: "x12"
      element :implementation_convention_reference, String, tag: "ST03__ImplementationConventionReference", namespace: "x12"
    end
  end
end