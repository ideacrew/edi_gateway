# frozen_string_literal: true

module Inbound834
  # Create the inbound transaction record representing an 834.
  class CreateTransaction
    include Dry::Monads[:result, :do, :try]

    # Create the transaction from the payload and headers.
    # @param opts [Hash] the operation options
    # @option opts :payload [String] the 834 XML payload
    # @option opts :headers [Headers] the message headers
    # @return [Dry::Result<Inbound834Transaction>] the created transaction
    def call(opts = {})
      payload = opts[:payload]
      headers = opts[:headers]
      gateway_envelope = yield ExtractGatewayEnvelope.new.call(headers)
      one_time_tag = yield calculate_one_time_tag(gateway_envelope, payload)
      transaction_record = yield build_transaction_record(gateway_envelope, one_time_tag)
      inserted_record = yield persist_record(transaction_record)
      persist_payload(inserted_record, payload)
    end

    protected

    def calculate_one_time_tag(envelope, payload)
      CalculateOneTimeTag.new.call(
        {
          envelope: envelope,
          payload: payload
        }
      )
    end

    def build_transaction_record(envelope, one_time_tag)
      BuildTransactionRecord.new.call({
                                        envelope: envelope,
                                        one_time_tag: one_time_tag
                                      })
    end

    def persist_record(transaction_record)
      creation_result = Try(::Mongo::Error::OperationFailure) do
        transaction_record.save!
        transaction_record
      end

      creation_result.or do |_e|
        Failure(:already_processed)
      end
    end

    # rubocop:disable Style/StringConcatenation
    def persist_payload(transaction_record, payload)
      transaction_record.payload = PayloadWrapper.new(payload, transaction_record.one_time_tag + ".xml")
      transaction_record.save!
      Success(transaction_record)
    end
    # rubocop:enable Style/StringConcatenation
  end
end