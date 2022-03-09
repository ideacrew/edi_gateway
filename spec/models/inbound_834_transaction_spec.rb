# frozen_string_literal: true

require "rails_helper"
=begin
RSpec.describe Inbound834Transaction, "given valid parameters" do

  let(:params) do
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
      b2b_document_definition: "834Def",
      one_time_tag: "OTT"
    }
  end

  subject do
    described_class.new(params)
  end

  it "is valid" do
    expect(subject.valid?).to be_truthy
  end
end

RSpec.describe Inbound834Transaction, "given a duplicate one time tag" do

  let(:params) do
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
      b2b_document_definition: "834Def",
      one_time_tag: "OTT"
    }
  end

  it "is does not save" do
    described_class.delete_all
    described_class.create_indexes
    described_class.create!(params)
    second_record = described_class.new(params)
    expect { second_record.save! }.to raise_error(Mongo::Error::OperationFailure)
    described_class.delete_all
  end
end
=end