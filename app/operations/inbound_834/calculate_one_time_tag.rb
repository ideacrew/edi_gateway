# frozen_string_literal: true

module Inbound834
  # Calculate the one-time tag for the inbound 834.
  # This prevents us from processing the same payload more than once.
  class CalculateOneTimeTag
    send(:include, Dry::Monads[:result, :do, :try])

    # Calculate the one-time tag from a given payload and envelope.
    # @param opts [Hash] the operation options
    # @option opts :payload [String] the 834 XML payload
    # @option opts :envelope [AcaX12Entities::X220A1::GatewayEnvelope] the
    #   GatewayEnvelope for the incoming 834
    # @return [Dry::Result<String>] the calculated tag
    def call(opts = {})
      payload = opts[:payload]
      envelope = opts[:envelope]
      calculate_tag(envelope, payload)
    end

    protected

    # There are several important properties to a OTT:
    #  * It needs to be unique for each transaction
    #  * It needs to have a length <= 1024 bytes so we can use it as a mongoid
    #    index key
    def calculate_tag(envelope, payload)
      tag_result = Try do
        payload_length = payload.bytesize
        payload_sha = Digest::SHA2.new(512).hexdigest payload
        [
          envelope.interchange_sender_id, # 15 bytes
          envelope.interchange_receiver_id, # 15 bytes
          envelope.interchange_timestamp.to_i.to_s, # Up to ~15 digits
          envelope.interchange_control_number, # 9 bytes
          envelope.group_control_number, # 9 bytes
          envelope.oracle_gateway_envelope.b2b_message_id, # Max 64 bytes?
          payload_sha, # 128 bytes
          payload_length.to_s # Max length is ~12 digits
        ].join("_")
      end
      tag_result.or do |e|
        Failure(e)
      end
    end
  end
end
