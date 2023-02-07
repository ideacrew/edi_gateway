# frozen_string_literal: true

RSpec.describe Locations::Addresses::ValidationStatus, type: :model, db_clean: :before do
  context 'and valid params are used to initialize an instance' do
    let(:moment) { DateTime.now }

    let(:is_valid) { true }
    let(:authority) { 'SmartyStreets' }
    let(:payload) { { validated_at: validated_at, street: '123 Main St', city: 'Anywhere', state: 'md' }.to_s }
    let(:validated_at) { moment }

    let(:required_params) { { is_valid: is_valid, authority: authority, validated_at: validated_at } }
    let(:optional_params) { { payload: payload } }
    let(:all_params) { required_params.merge(optional_params) }

    it 'should initialize a model' do
      result = described_class.new(all_params)
      expect(result.to_hash.except(:id, :created_at, :updated_at)).to eq all_params
    end
  end
end
