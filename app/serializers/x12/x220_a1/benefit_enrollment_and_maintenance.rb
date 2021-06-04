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

      def to_domain_parameters
        transaction_set_header_parameters.merge(
          beginning_segment_parameters
        ).merge(
          sponsor_parameters
        ).merge(
          payer_parameters
        ).merge(
          tpa_or_broker_parameters
        ).merge(
          member_parameters
        )
      end

      protected

      def transaction_set_header_parameters
        transaction_set_header ? transaction_set_header.to_domain_parameters : {}
      end

      def beginning_segment_parameters
        beginning_segment ? beginning_segment.to_domain_parameters : {}
      end

      def sponsor_parameters
        s_parameters = sponsor ? sponsor.to_domain_parameters : {}
        {
          sponsor: {}
        }
      end

      def payer_parameters
        p_parameters = payer ? payer.to_domain_parameters : {}
        {
          payer: p_parameters
        }
      end

      def tpa_or_broker_parameters
        tpa_or_broker.inject(Hash.new) do |results, element|
          results.merge(element.to_domain_parameters)
        end
      end

      def member_parameters
        {
          members: member_loops.map(&:to_domain_parameters)
        }
      end
    end
  end
end