# frozen_string_literal: true

module Inbound834
  # Map the inbound Envelope and transaction data to a database record.
  class BuildTransactionRecord
    send(:include, Dry::Monads[:result, :do])

    # Map the inbound Envelope and transaction data to a database record.
    # @param opts [Hash] the operation options
    # @option opts :one_time_tag [String] the one time tag
    # @option opts :envelope [AcaX12Entities::X220A1::GatewayEnvelope] the
    #   envelope information
    def call(opts = {})
      one_time_tag = opts[:one_time_tag]
      envelope = opts[:envelope]
      new_record = yield map_attributes_to_record(envelope, one_time_tag)
      validate_record(new_record)
    end

    protected

    def validate_record(record)
      record.valid? ? Success(record) : Failure(record.errors)
    end

    def map_attributes_to_record(envelope, one_time_tag)
      attributes = extract_attributes(envelope, one_time_tag)
      Success(::Inbound834Transaction.new(attributes))
    end

    # rubocop:disable Metrics/MethodLength
    def extract_attributes(envelope, one_time_tag)
      envelope_attributes = envelope.to_h.symbolize_keys.slice(
        :interchange_control_number,
        :interchange_sender_qualifier,
        :interchange_sender_id,
        :interchange_receiver_qualifier,
        :interchange_receiver_id,
        :interchange_timestamp,
        :functional_group_count,
        :group_control_number,
        :application_senders_code,
        :application_receivers_code,
        :group_creation_timestamp,
        :transaction_set_count
      )

      oracle_attributes = envelope.oracle_gateway_envelope.to_h.symbolize_keys.slice(
        :b2b_message_id,
        :b2b_created_at,
        :b2b_updated_at,
        :b2b_business_message_id,
        :b2b_protocol_message_id,
        :b2b_in_trading_partner,
        :b2b_out_trading_partner,
        :b2b_message_status,
        :b2b_direction,
        :b2b_document_type_name,
        :b2b_document_protocol_name,
        :b2b_document_protocol_version,
        :b2b_document_definition,
        :b2b_conversation_id,
        :b2b_message_correlation_id
      )

      filtered_attributes = envelope_attributes.merge(oracle_attributes).reject do |_k, v|
        v.blank?
      end
      filtered_attributes.merge(
        {
          one_time_tag: one_time_tag
        }
      )
    end
    # rubocop:enable Metrics/MethodLength
  end
end