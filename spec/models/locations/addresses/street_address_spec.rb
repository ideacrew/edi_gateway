# frozen_string_literal: true

require './spec/shared_examples/locations/addresses/shared_addresses'

RSpec.describe Locations::Addresses::StreetAddress, type: :model, db_clean: :before do
  include_context 'shared_addresses'

  context 'and valid params are used to initialize an instance' do
    let(:kind) { 'home' }
    let(:street_predirection) { 'South' }
    let(:address_1) { '1406 Albright St' }
    let(:address_2) { 'Apt 123' }
    let(:address_3) { 'Garden Level' }
    let(:street_postdirection) { 'SE' }
    let(:city_name) { 'Boise' }
    let(:state_abbreviation) { 'ID' }
    let(:zip_code) { '83705' }
    let(:zip_plus_four_code) { '0587' }

    let(:county_name) { 'Ada' }
    let(:county_fips_code) { '16001' }
    let(:state_fips_code) { '16' }

    let(:validation_status) { Locations::Addresses::ValidationStatus.new(shared_addresses_validation_status) }

    let(:has_fixed_address) { true }
    let(:lives_outside_state_temporarily) { false }

    let(:moment) { DateTime.now }

    let(:params) do
      {
        kind: kind,
        street_predirection: street_predirection,
        address_1: address_1,
        address_2: address_2,
        address_3: address_3,
        city_name: city_name,
        state_abbreviation: state_abbreviation,
        street_postdirection: street_postdirection,
        zip_code: zip_code,
        zip_plus_four_code: zip_plus_four_code,
        county_name: county_name,
        has_fixed_address: has_fixed_address,
        lives_outside_state_temporarily: lives_outside_state_temporarily
      }
    end

    it 'should initialize a model' do
      result = described_class.new(params)
      expect(result.to_hash.except(:id, :created_at, :updated_at, :start_on, :end_on, :validation_status)).to eq params
    end

    it 'the model should include an embedded validation_status instance' do
      result = described_class.new(params)
      result.validation_status = validation_status
      expect(result.validation_status.to_hash).to eq validation_status.to_hash
    end
  end
end
