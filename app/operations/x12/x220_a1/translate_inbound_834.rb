# frozen_string_literal: true

module X12
  module X220A1
    # Take an ASC X12 834 payload in XML, and convert it to the
    # aca_x12_entities domain model.
    class TranslateInbound834
      send(:include, Dry::Monads[:result, :do, :try])

      def call(payload)
        mapper = yield parse_payload(payload)
        domain_parameters = yield transform_to_parameters(mapper)
        AcaX12Entities::Operations::X220A1::BuildBenefitEnrollmentAndMaintenance.new.call(
          domain_parameters
        )
      end

      protected

      def parse_payload(payload)
        result = Try do
          BenefitEnrollmentAndMaintenance.parse(payload, single: true)
        end.or(Failure(:parse_payload_failed))
        return result unless result.success?
        return Failure(:parse_payload_failed) if result.value!.blank?
        result
      end

      def transform_to_parameters(mapper)
        Success(mapper.to_domain_parameters)
      end
    end
  end
end