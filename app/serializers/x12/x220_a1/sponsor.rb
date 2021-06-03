# frozen_string_literal: true

module X12
  module X220A1
    # Sponsor - loop 1000B.
    class Sponsor
      include HappyMapper
      register_namespace 'x12', 'urn:x12:schemas:005:010:834A1A1:BenefitEnrollmentAndMaintenance'

      tag "Loop_1000A"
      namespace 'x12'

      has_one :sponsor_name, SponsorName

      delegate :plan_sponsor_name, to: :sponsor_name, allow_nil: true
      delegate :identification_code_qualifier, to: :sponsor_name, allow_nil: true
      delegate :sponsor_identifier, to: :sponsor_name, allow_nil: true
    end
  end
end