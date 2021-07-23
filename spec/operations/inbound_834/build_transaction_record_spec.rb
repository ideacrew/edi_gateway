# frozen_string_literal: true

require "rails_helper"

RSpec.describe Inbound834::BuildTransactionRecord, "given a bogus one time tag and an empty envelope" do
  let(:envelope_properties) do
    {}
  end

  let(:envelope) do
    instance_double(
      AcaX12Entities::X220A1::GatewayEnvelope,
      to_h: envelope_properties,
      oracle_gateway_envelope: nil
    )
  end

  let(:one_time_tag) do
    nil
  end

  let(:params) do
    {
      envelope: envelope,
      one_time_tag: one_time_tag
    }
  end

  subject do
    described_class.new.call(params)
  end

  it "fails" do
    expect(subject.success?).to be_falsey
  end
end

RSpec.describe Inbound834::BuildTransactionRecord, "given a valid one time tag and an complete envelope" do
  let(:envelope_properties) do
    {
      interchange_control_number: "12345",
      interchange_sender_qualifier: "FI",
      interchange_sender_id: "543219",
      interchange_receiver_qualifier: "FI",
      interchange_receiver_id: "543217",
      interchange_timestamp: DateTime.now,
      group_control_number: "123456",
      application_senders_code: "ME0",
      application_receivers_code: "SHP",
      group_creation_timestamp: DateTime.now
    }
  end

  let(:oracle_envelope_properties) do
    {
      b2b_message_id: "1234",
      b2b_created_at: DateTime.now,
      b2b_updated_at: DateTime.now,
      b2b_business_message_id: "4321",
      b2b_protocol_message_id: "54321",
      b2b_in_trading_partner: "ME0",
      b2b_out_trading_partner: "CF",
      b2b_message_status: "MSG_ERROR",
      b2b_direction: "INBOUND",
      b2b_document_type_name: "834",
      b2b_document_protocol_name: "X12",
      b2b_document_protocol_version: "X220A1",
      b2b_document_definition: "834Def"
    }
  end

  let(:oracle_gateway_envelope) do
    instance_double(
      AcaX12Entities::X220A1::OracleGatewayEnvelope,
      to_h: oracle_envelope_properties
    )
  end

  let(:envelope) do
    instance_double(
      AcaX12Entities::X220A1::GatewayEnvelope,
      to_h: envelope_properties,
      oracle_gateway_envelope: oracle_gateway_envelope
    )
  end

  let(:one_time_tag) do
    "SOME PROVIDED ONE TIME TAG"
  end

  let(:params) do
    {
      envelope: envelope,
      one_time_tag: one_time_tag
    }
  end

  subject do
    described_class.new.call(params)
  end

  it "saves the values" do
    expect(subject.success?).to be_truthy
    expect(subject.value!.is_a?(Inbound834Transaction)).to be_truthy
  end
end