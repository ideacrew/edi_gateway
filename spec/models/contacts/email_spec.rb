# frozen_string_literal: true

RSpec.describe Contacts::Email, type: :model, db_clean: :before do
  context 'and valid params are used to initialize an instance' do
    let(:kind) { 'home' }
    let(:address) { 'george.jetson@example.com' }

    let(:all_params) { { kind: kind, address: address } }

    it 'should initialize a model' do
      result = described_class.new({ kind: kind, address: address })
      expect(result.to_hash.except(:id, :created_at, :updated_at)).to eq all_params
    end
  end
end
