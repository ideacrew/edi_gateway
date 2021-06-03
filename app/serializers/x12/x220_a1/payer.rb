# frozen_string_literal: true

module X12
  module X220A1
    # Payer - loop 1000B.
    class Payer
      include HappyMapper
      register_namespace 'x12', 'urn:x12:schemas:005:010:834A1A1:BenefitEnrollmentAndMaintenance'

      tag "Loop_1000B"
      namespace 'x12'

      has_one :payer_name, PayerName

      delegate :insurer_name, to: :payer_name, allow_nil: true
      delegate :identification_code_qualifier, to: :payer_name, allow_nil: true
      delegate :insurer_identifier, to: :payer_name, allow_nil: true
    end
  end
end