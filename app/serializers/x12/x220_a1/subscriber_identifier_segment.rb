# frozen_string_literal: true

module X12
  module X220A1
    # Subscriber identifier segment under loop 2000.
    class SubscriberIdentifierSegment
      include HappyMapper
      register_namespace 'x12', 'urn:x12:schemas:005:010:834A1A1:BenefitEnrollmentAndMaintenance'

      tag "REF_SubscriberIdentifier_2000"
      namespace 'x12'

      element :subscriber_identifier, String, tag: "REF02__SubscriberIdentifier", namespace: "x12"
    end
  end
end