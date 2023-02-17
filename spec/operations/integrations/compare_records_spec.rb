# frozen_string_literal: true

RSpec.describe Integrations::CompareRecords do
  #   context 'with invalid params' do
  #     it 'return failure' do
  #       result = subject.call({})
  #       expect(result.failure?).to be_truthy
  #       expect(result.failure).to include 'contract_holder_sync_job required'
  #       expect(result.failure).to include 'primary hbx id'
  #       expect(result.failure).to include 'at least one of subscriber or responsible party policies required'
  #     end
  #   end

  let(:old_home_address) do
    {
      address_1: '138 Townsend Ave.',
      address_2: 'Unit 7',
      address_3: '',
      city_name: 'test Harbor',
      county_name: nil,
      kind: 'home',
      state_abbreviation: 'ME',
      zip_code: '00079'
    }
  end

  let(:new_home_address) do
    {
      address_1: '138 New York Ave.',
      address_2: 'Unit 81',
      address_3: '',
      city_name: 'New Harbor',
      county_name: nil,
      kind: 'home',
      state_abbreviation: 'ME',
      zip_code: '00179'
    }
  end

  let(:old_mailing_address) do
    {
      address_1: '79 King St',
      address_2: 'Apt 2',
      address_3: '',
      city_name: 'test',
      county_name: nil,
      kind: 'mailing',
      state_abbreviation: 'ME',
      zip_code: '00097'
    }
  end

  let(:new_mailing_address) do
    {
      address_1: '79 Gosnell St',
      address_2: 'Apt 20',
      address_3: '',
      city_name: 'vienna',
      county_name: nil,
      kind: 'mailing',
      state_abbreviation: 'ME',
      zip_code: '01897'
    }
  end

  context 'old home address & mailing address got updated' do
    it 'should return changes' do
      subject = described_class.new(AcaEntities::Locations::Address, :kind)
      subject.add_old_entry([old_home_address, old_mailing_address])
      subject.add_new_entry([new_home_address, new_mailing_address])
      subject.changed_records

      expect(subject.records_to_delete).to be_empty
      expect(subject.records_to_create).to be_empty
      expect(subject.records_to_update).to match_array([new_mailing_address, new_home_address])
    end
  end

  context 'old mailing address present' do
    context 'and new mailing address not present' do
      it 'should return changes' do
        subject = described_class.new(AcaEntities::Locations::Address, :kind)
        subject.add_old_entry([old_home_address, old_mailing_address])
        subject.add_new_entry([new_home_address])
        subject.changed_records

        expect(subject.records_to_delete).to match_array([old_mailing_address])
        expect(subject.records_to_create).to be_empty
        expect(subject.records_to_update).to match_array([new_home_address])
      end
    end
  end

  context 'old home address present' do
    context 'and new home address not present' do
      it 'should return changes' do
        subject = described_class.new(AcaEntities::Locations::Address, :kind)
        subject.add_old_entry([old_home_address, old_mailing_address])
        subject.add_new_entry([new_mailing_address])
        subject.changed_records

        expect(subject.records_to_delete).to match_array([old_home_address])
        expect(subject.records_to_create).to be_empty
        expect(subject.records_to_update).to match_array([new_mailing_address])
      end
    end
  end

  context 'old mailing address not present' do
    context 'and new mailing address provided' do
      it 'should return changes' do
        subject = described_class.new(AcaEntities::Locations::Address, :kind)
        subject.add_old_entry([old_home_address])
        subject.add_new_entry([new_mailing_address])
        subject.changed_records

        expect(subject.records_to_delete).to match_array([old_home_address])
        expect(subject.records_to_create).to match_array([new_mailing_address])
        expect(subject.records_to_update).to match_array([])
      end
    end
  end

  context 'old home address not present' do
    context 'and new mailing address provided' do
      it 'should return changes' do
        subject = described_class.new(AcaEntities::Locations::Address, :kind)
        subject.add_old_entry([old_mailing_address])
        subject.add_new_entry([new_home_address, new_mailing_address])
        subject.changed_records

        expect(subject.records_to_delete).to match_array([])
        expect(subject.records_to_create).to match_array([new_home_address])
        expect(subject.records_to_update).to match_array([new_mailing_address])
      end
    end
  end
end
