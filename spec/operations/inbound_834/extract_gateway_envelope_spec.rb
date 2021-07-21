# frozen_string_literal: true

require "rails_helper"

RSpec.describe Inbound834::ExtractGatewayEnvelope, "given an empty set of properties" do
  let(:params) do
    {}
  end

  subject do
    Inbound834::ExtractGatewayEnvelope.new.call(params)
  end

  it "fails" do
    expect(subject.success?).to be_falsey
  end
end

RSpec.describe Inbound834::ExtractGatewayEnvelope, "given a valid set of properties" do
  let(:params) do
    {
      interchange_control_number: "12345678",
      interchange_sender_qualifier: "FI",
      interchange_sender_id: "987654321",
      interchange_receiver_qualifier: "FI",
      interchange_receiver_id: "123456789",
      interchange_timestamp: DateTime.now,
      functional_group_count: 13,
      group_control_number: "12345",
      application_senders_code: "ME0",
      application_receivers_code: "IND",
      group_creation_timestamp: DateTime.now,
      transaction_set_count: 25,
      b2b_message_id: "SOME MESSAGE ID",
      b2b_created_at: DateTime.now,
      b2b_updated_at: DateTime.now,
      b2b_business_message_id: "SOME BUSINESS MESSAGE ID",
      b2b_protocol_message_id: "SOME PROTOCOL MESSAGE ID",
      b2b_in_trading_partner: "CF",
      b2b_out_trading_partner: "ME0",
      b2b_message_status: "MSG_WAIT_TA1",
      b2b_direction: "INBOUND",
      b2b_document_type_name: "834",
      b2b_document_protocol_name: "X12",
      b2b_document_protocol_version: "X220A1",
      b2b_document_definition: "834Def"
    }
  end

  subject do
    Inbound834::ExtractGatewayEnvelope.new.call(params)
  end

  it "succeeds" do
    expect(subject.success?).to be_truthy
  end

  it "returns a gateway envelope object" do
    expect(subject.value!.is_a?(AcaX12Entities::X220A1::GatewayEnvelope)).to be_truthy
  end
end