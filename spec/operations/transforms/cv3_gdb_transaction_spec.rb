# frozen_string_literal: true

require 'rails_helper'
require 'shared_examples/gdb_transaction_params'

RSpec.describe Transforms::Cv3GdbTransaction, db_clean: :before do
  subject { described_class.new }
  include_context 'gdb_transaction_params'

  context 'Given an empty response' do
    it 'should fail the transformation' do
      result = subject.call({})
      expect(result.failure?).to be_truthy
    end
  end

  context 'Given an empty subscriber_id' do
    it 'should fail the transformation' do
      result = subject.call({response: [OpenStruct.new(policy: "test")], subscriber_id: ""})
      expect(result.failure?).to be_truthy
    end
  end

  context 'Given an invalid response' do
    it 'should fail the transformation' do
      result = subject.call({response: [OpenStruct.new(policy: "test")], subscriber_id: "12345"})
      expect(result.failure?).to be_truthy
      expect(result.failure).to eq("Invalid Policy response")
    end
  end

  context 'Given a valid GDB transaction' do
    let(:params) { {response: policy_response, subscriber_id: "12345"}}
    it "should successfully transform the payload according to gdb transaction contract" do
      result = subject.call(params)
      response = AcaEntities::Ledger::Contracts::GdbTransactionContract.new.call(result.value!)
      expect(response.failure?).to be_falsey
    end
  end
end