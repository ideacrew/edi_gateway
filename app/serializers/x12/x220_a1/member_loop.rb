# frozen_string_literal: true

module X12
  module X220A1
    # Member loops - Loop 2000.
    class MemberLoop
      include HappyMapper
      register_namespace 'x12', 'urn:x12:schemas:005:010:834A1A1:BenefitEnrollmentAndMaintenance'

      tag "Loop_2000"
      namespace 'x12'

      has_one :member_level_detail, MemberLevelDetail
      has_one :subscriber_identifier_segment, SubscriberIdentifierSegment
      has_many :member_supplemental_identifiers, MemberSupplementalIdentifier
      has_many :member_level_dates, MemberLevelDate
      has_many :member_coverage, MemberCoverage

      delegate :subscriber_indicator, to: :member_level_detail, allow_nil: true
      delegate :maintenance_type_code, to: :member_level_detail, allow_nil: true
      delegate :maintenance_reason_code, to: :member_level_detail, allow_nil: true
      delegate :subscriber_identifier, to: :subscriber_identifier_segment, allow_nil: true

      def to_domain_parameters
        {
          subscriber_indicator: subscriber_indicator,
          subscriber_identifier: subscriber_identifier,
          maintenance_type_code: maintenance_type_code,
          maintenance_reason_code: maintenance_reason_code,
          member_supplemental_identifiers: member_supplemental_identifiers.map(&:to_domain_parameters),
          member_level_dates: member_level_dates.map(&:to_domain_parameters),
          member_coverage: member_coverage.map(&:to_domain_parameters)
        }
      end
    end
  end
end