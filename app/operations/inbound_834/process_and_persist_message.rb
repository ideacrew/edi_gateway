# frozen_string_literal: true

module Inbound834
  # Build all records for inbound 834 transactions, or report failure to do so.
  class ProcessAndPersistMessage
    send(:include, Dry::Monads[:result, :do, :try])

    # Create all records from the payload and headers.
    # @param params [Hash] the operation options
    # @option params :payload [String] the 834 XML payload
    # @option params :headers [Hash] the message headers
    # @return [Dry::Result<Array<Inbound834Transaction, AcaX12Entities::X220A1::BenefitEnrollmentAndMaintenance>>] the created objects or failure
    def call(params)
      payload = params[:payload]
      transaction_record, envelope = yield CreateTransactionAndEnvelope.new.call(params)
      domain_model = yield build_834_domain_model(payload, envelope)
      updated_transaction_record = yield update_transaction_record(transaction_record, domain_model)
      Success([updated_transaction_record, domain_model])
    end

    protected

    def build_834_domain_model(payload, envelope)
      ::X12::X220A1::TranslateInbound834.new.call({
                                                    payload: payload,
                                                    envelope: envelope
                                                  })
    end

    def update_transaction_record(transaction_record, domain_model)
      update_result = transaction_record.update_attributes({
                                                             transaction_set_control_number: domain_model.transaction_set_control_number,
                                                             transaction_set_reference_number: domain_model.transaction_set_reference_number
                                                           })
      update_result ? Success(transaction_record) : Failure(transaction_record.errors)
    end
  end
end