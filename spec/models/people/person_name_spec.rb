# frozen_string_literal: true

RSpec.describe People::PersonName, type: :model do
  context "Given valid params to initialize a #{described_class} instance" do
    let(:first_name) { 'George' }
    let(:middle_name) { 'William' }
    let(:last_name) { 'Jetson' }
    let(:name_pfx) { 'Dr' }
    let(:name_sfx) { 'III' }
    let(:alternate_name) { 'Willy' }

    let(:valid_params) do
      {
        first_name: first_name,
        middle_name: middle_name,
        last_name: last_name,
        name_pfx: name_pfx,
        name_sfx: name_sfx,
        alternate_name: alternate_name
      }
    end

    it 'the new instance should be valid' do
      result = described_class.new(valid_params)
      expect(result.valid?).to be_truthy
    end

    context '#to_hash' do
      it 'should return a hash with all provided attributes and values' do
        result = described_class.new(valid_params)
        expect(result.to_hash.except(:id, :created_at, :updated_at)).to eq valid_params
      end

      it 'should pass Domain contract validation' do
        result = AcaEntities::Contracts::People::PersonNameContract.new.call(valid_params)
        expect(result.success?).to be_truthy
      end
    end
  end
end
