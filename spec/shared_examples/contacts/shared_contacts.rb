# frozen_string_literal: true

RSpec.shared_context 'shared_contacts' do
  let(:phone_primary) { true }
  let(:phone_kind) { 'mobile' }
  let(:phone_country_code) { '+1' }
  let(:phone_area_code) { '208' }
  let(:phone_number) { '5551212' }
  let(:phone_extension) { '411' }

  let(:shared_contacts_phone) do
    {
      primary: phone_primary,
      kind: phone_kind,
      country_code: phone_country_code,
      area_code: phone_area_code,
      number: phone_number,
      extension: phone_extension
    }
  end

  let(:email_kind) { 'home' }
  let(:email_address) { 'george.jetson@example.com' }

  let(:shared_contacts_email) { { kind: email_kind, address: email_address } }
end
