# frozen_string_literal: true

module X12
  module X220A1
    # Loop 1000C - tpa or broker.
    class TpaOrBroker
      include HappyMapper
      register_namespace 'x12', 'urn:x12:schemas:005:010:834A1A1:BenefitEnrollmentAndMaintenance'

      tag "Loop_1000C"
      namespace 'x12'

      has_one :tpa_broker_name, TpaBrokerName

      delegate :tpa_or_broker_name, to: :tpa_broker_name, allow_nil: true
      delegate :identification_code_qualifier, to: :tpa_broker_name, allow_nil: true
      delegate :tpa_or_broker_identifier, to: :tpa_broker_name, allow_nil: true
    end
  end
end