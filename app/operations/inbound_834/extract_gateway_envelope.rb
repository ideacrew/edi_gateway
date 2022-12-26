# frozen_string_literal: true

module Inbound834
  # Extract GatewayEnvelope information from an inbound 834 message.
  class ExtractGatewayEnvelope
    send(:include, Dry::Monads[:result, :do, :try])

    # Extract the GatewayEnvelope information.
    # @param headers [Hash] the hash of headers from the AMQP message.
    # @return [Dry::Result<AcaX12Entities::X220A1::GatewayEnvelope>] the new
    #   GatewayEnvelope or a reason for failure
    def call(headers = {})
      header_properties = yield validate_headers(headers)
      build_gateway_envelope(header_properties)
    end

    protected

    def validate_headers(headers)
      symbolized_headers = headers.to_h.symbolize_keys
      b2b_headers = symbolized_headers.select do |k, v|
        k.to_s.starts_with?("b2b_") && !v.blank?
      end
      normal_headers = symbolized_headers.reject do |k, v|
        k.to_s.starts_with?("b2b_") || v.blank?
      end
      properties = normal_headers.merge(
        {
          oracle_gateway_envelope: b2b_headers
        }
      )
      validation_result = ::AcaX12Entities::Contracts::X220A1::GatewayEnvelopeContract.new.call(
        properties
      )
      validation_result.success? ? Success(validation_result.values) : Failure(validation_result.errors)
    end

    def build_gateway_envelope(properties)
      build_result = Try do
        ::AcaX12Entities::X220A1::GatewayEnvelope.new(properties)
      end
      build_result.or do |e|
        Failure(e)
      end
    end
  end
end
