# frozen_string_literal: true

require "rails_helper"
=begin
RSpec.describe Inbound834::ProcessAndPersistMessage, "given valid headers and a payload for a transaction it has never seen" do
  let(:headers) do
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
      group_creation_timestamp: DateTime.now,
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

  let(:params) do
    {
      headers: headers,
      payload: payload
    }
  end

  subject do
    described_class.new.call(params)
  end

  let(:payload_operation) do
    instance_double(
      ::X12::X220A1::TranslateInbound834
    )
  end

  let(:domain_model) do
    instance_double(
      ::AcaX12Entities::X220A1::BenefitEnrollmentAndMaintenance,
      transaction_set_control_number: "A TSCN",
      transaction_set_reference_number: "A TSRN"
    )
  end

  before(:each) do
    Inbound834Transaction.delete_all
    allow(::X12::X220A1::TranslateInbound834).to receive(:new).and_return(payload_operation)
    allow(payload_operation).to receive(:call) do |params|
      expect(params[:payload]).to eq payload
    end.and_return(
      Dry::Monads::Result::Success.call(domain_model)
    )
  end

  after(:each) do
    Inbound834Transaction.delete_all
  end

  it "succeeds" do
    expect(subject.success?).to be_truthy
  end

  it "returns the domain model" do
    expect(subject.value!.last).to eq domain_model
  end

  it "returns the record" do
    expect(subject.value!.first.is_a?(Inbound834Transaction)).to be_truthy
  end
end
=end