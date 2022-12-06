# frozen_string_literal: true

RSpec.shared_context 'shared_people' do
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
end
