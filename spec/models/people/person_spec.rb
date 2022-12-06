# frozen_string_literal: true

require './spec/shared_examples/people/shared_people'
require './spec/shared_examples/locations/addresses/shared_addresses'
require './spec/shared_examples/contacts/shared_contacts'

RSpec.describe People::Person, type: :model, db_clean: :before do
  context 'and validated params are used to initialize an instance' do
    include_context 'shared_people'
    include_context 'shared_contacts'
    include_context 'shared_addresses'

    let(:name) { shared_people_person_name }
    let(:emails) { [shared_contacts_email] }
    let(:phones) { [shared_contacts_phone] }
    let(:addresses) { [shared_addresses_validated_street_address] }

    let(:valid_params) { { name: name, emails: emails, phones: phones, addresses: addresses } }

    it 'the new instance should be valid' do
      expect(described_class.new(valid_params).valid?).to be_truthy
    end

    context 'and it should save and retreive from database' do
      it 'should persist' do
        result = described_class.new(valid_params)
        expect(result.save).to be_truthy
        expect(described_class.all.size).to eq 1

        persisted_person = described_class.find(result.id)
        expect(persisted_person).to be_present
      end
    end

    # context '#to_hash' do
    #   it 'should return a hash with all provided attributes and values' do
    #     result = described_class.new(valid_params)
    #     expect(result.to_hash.except(:id, :created_at, :updated_at)).to eq valid_params
    #   end

    #   it 'should pass Domain contract validation' do
    #     result = AcaEntities::Contracts::People::PersonContract.new.call(valid_params)
    #     expect(result.success?).to be_truthy
    #   end
    # end
  end
end
