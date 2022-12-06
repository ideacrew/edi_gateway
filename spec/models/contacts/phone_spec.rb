# frozen_string_literal: true

RSpec.describe Contacts::Phone, type: :model, db_clean: :before do
  context 'and valid params are used to initialize an instance' do
    let(:primary) { true }
    let(:kind) { 'mobile' }
    let(:country_code) { '+1' }
    let(:area_code) { '208' }
    let(:number) { '5551212' }
    let(:extension) { '411' }

    let(:all_params) do
      {
        primary: primary,
        kind: kind,
        country_code: country_code,
        area_code: area_code,
        number: number,
        extension: extension
      }
    end

    it 'should initialize a model' do
      result =
        described_class.new(
          {
            primary: primary,
            kind: kind,
            country_code: country_code,
            area_code: area_code,
            number: number,
            extension: extension
          }
        )
      expect(result.to_hash.except(:id, :created_at, :updated_at)).to eq all_params
    end
  end
end
