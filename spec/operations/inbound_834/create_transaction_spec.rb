# frozen_string_literal: true

require "rails_helper"

RSpec.describe Inbound834::CreateTransaction, "given valid headers and a payload for a transaction it has never seen" do
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

  let(:payload) do
    "<xml xmlns=\"urn:whatever\"></xml>"
  end

  let(:headers) do
    oracle_envelope_properties.merge(envelope_properties)
  end

  let(:params) do
    {
      headers: headers,
      payload: payload
    }
  end

  subject do
    described_class.new.call(params)
  end

  before(:each) do
    Inbound834Transaction.delete_all
  end

  after(:each) do
    Inbound834Transaction.delete_all
  end

  it "succeeds" do
    expect(subject.success?).to be_truthy
  end

  it "returns the new transaction record" do
    expect(subject.value!.is_a?(Inbound834Transaction)).to be_truthy
  end

  it "persists the payload" do
    expect(subject.value!.payload.file.nil?).to be_falsey
    expect(subject.value!.payload.file.read).to eq payload
  end
end

RSpec.describe Inbound834::CreateTransaction, "given valid headers and a payload for a transaction it has already seen" do
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

  let(:payload) do
    "<xml xmlns=\"urn:whatever\"></xml>"
  end

  let(:headers) do
    oracle_envelope_properties.merge(envelope_properties)
  end

  let(:params) do
    {
      headers: headers,
      payload: payload
    }
  end

  let(:first_process) do
    described_class.new.call(params)
  end

  subject do
    described_class.new.call(params)
  end

  before(:each) do
    Inbound834Transaction.delete_all
  end

  after(:each) do
    Inbound834Transaction.delete_all
  end

  it "fails" do
    first_process
    expect(subject.success?).to be_falsey
  end

  it "returns is marked as already processed" do
    first_process
    expect(subject.failure).to eq :already_processed
  end
end