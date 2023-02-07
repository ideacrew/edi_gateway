# frozen_string_literal: true

RSpec.shared_context 'shared_addresses' do
  let(:validation_status_moment) { DateTime.now }

  # ValidationStatus
  let(:validation_status_is_valid) { true }
  let(:validation_status_authority) { 'SmartyStreets' }
  let(:validation_status_payload) do
    { validated_at: validation_status_moment, street: '123 Main St', city: 'Anywhere', state: 'md' }.to_s
  end

  let(:validation_status_validated_at) { validation_status_moment }

  let(:shared_addresses_validation_status) do
    {
      is_valid: validation_status_is_valid,
      authority: validation_status_authority,
      payload: validation_status_payload,
      validated_at: validation_status_validated_at
    }
  end

  # StreetAddress
  let(:street_address_kind) { 'home' }
  let(:street_address_address_1) { '1406 Albright St' }
  let(:street_address_city_name) { 'Boise' }
  let(:street_address_state_abbreviation) { 'ID' }
  let(:street_address_county_name) { 'Ada' }
  let(:street_address_zip_code) { '83705' }
  let(:street_address_zip_plus_four_code) { '0587' }
  let(:street_address_has_fixed_address) { true }
  let(:street_address_lives_outside_state_temporarily) { false }

  let(:shared_addresses_street_address) do
    {
      kind: street_address_kind,
      address_1: street_address_address_1,
      city_name: street_address_city_name,
      state_abbreviation: street_address_state_abbreviation,
      zip_code: street_address_zip_code,
      zip_plus_four_code: street_address_zip_plus_four_code,
      county_name: street_address_county_name,
      has_fixed_address: street_address_has_fixed_address,
      lives_outside_state_temporarily: street_address_lives_outside_state_temporarily
    }
  end

  let(:shared_addresses_validated_street_address) do
    shared_addresses_street_address.merge(validation_status: shared_addresses_validation_status)
  end
end
