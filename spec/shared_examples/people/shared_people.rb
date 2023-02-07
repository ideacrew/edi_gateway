# frozen_string_literal: true

require './spec/shared_examples/contacts/shared_contacts'

RSpec.shared_context 'shared_people' do
  include_context 'shared_contacts'

  # Person
  let(:former_names) { [shared_people_person_name_primary_former] }
  let(:emails) { [shared_contacts_email] }
  let(:phones) { [shared_contacts_phone] }
  let(:addresses) { [shared_addresses_validated_street_address] }

  let(:shared_people_person_primary) do
    {
      name: shared_people_person_name,
      former_names: former_names,
      emails: emails,
      addresses: addresses,
      phones: phones
    }
  end

  let(:shared_people_person_spouse) do
    { name: shared_people_person_name_spouse, emails: emails, addresses: addresses, phones: phones }
  end

  let(:shared_people_person_daughter) do
    { name: shared_people_person_name_daughter, emails: emails, addresses: addresses, phones: phones }
  end

  let(:shared_people_person_son) do
    { name: shared_people_person_name_son, emails: emails, addresses: addresses, phones: phones }
  end

  # PersonName
  let(:person_name_first_name) { 'George' }
  let(:person_name_middle_name) { 'William' }
  let(:person_name_last_name) { 'Jetson' }
  let(:person_name_name_pfx) { 'Dr' }
  let(:person_name_name_sfx) { 'III' }
  let(:person_name_alternate_name) { 'Willy' }

  let(:shared_people_person_name) do
    {
      first_name: person_name_first_name,
      middle_name: person_name_middle_name,
      last_name: person_name_last_name,
      name_pfx: person_name_name_pfx,
      name_sfx: person_name_name_sfx,
      alternate_name: person_name_alternate_name
    }
  end

  let(:person_name_first_name_primary_former) { 'Willy' }
  let(:person_name_last_name_primary_former) { 'Jetson' }

  let(:shared_people_person_name_primary_former) do
    { first_name: person_name_first_name_primary_former, last_name: person_name_last_name_primary_former }
  end

  let(:person_name_first_name_spouse) { 'Jane' }
  let(:person_name_last_name_spouse) { 'Jetson' }

  let(:shared_people_person_name_spouse) do
    { first_name: person_name_first_name_spouse, last_name: person_name_last_name_spouse }
  end

  let(:person_name_first_name_daughter) { 'Judy' }
  let(:person_name_last_name_daughter) { 'Jetson' }

  let(:shared_people_person_name_daughter) do
    { first_name: person_name_first_name_daughter, last_name: person_name_last_name_daughter }
  end

  let(:person_name_first_name_son) { 'Elroi' }
  let(:person_name_last_name_son) { 'Jetson' }

  let(:shared_people_person_name_son) do
    { first_name: person_name_first_name_son, last_name: person_name_last_name_son }
  end
end
