# frozen_string_literal: true

module X12
  module X220A1
    # Top level 834 payload.
    class BenefitEnrollmentAndMaintenance
      include HappyMapper
      register_namespace 'x12', 'urn:x12:schemas:005:010:834A1A1:BenefitEnrollmentAndMaintenance'

      tag "X12_005010X220A1_834A1"
      namespace 'x12'

      has_one :transaction_set_header, TransactionSetHeader
      has_one :beginning_segment, BeginningSegment

      has_one :sponsor, Sponsor
      has_one :payer, Payer
      has_many :tpa_or_broker, TpaOrBroker

      has_many :member_loops, MemberLoop
    end
  end
end