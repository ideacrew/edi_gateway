# frozen_string_literal: true

module X12
  module X220A1
    class Payer
      include HappyMapper
      register_namespace 'x12', 'urn:x12:schemas:005:010:834A1A1:BenefitEnrollmentAndMaintenance'

      tag "Loop_1000B"
      namespace 'x12'
    end
  end
end