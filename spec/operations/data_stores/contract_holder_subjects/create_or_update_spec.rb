# frozen_string_literal: true

RSpec.describe DataStores::ContractHolderSubjects::CreateOrUpdate do
  subject { described_class.new }

  context 'with invalid params' do
    it 'return failure' do
      result = subject.call({})
      expect(result.failure?).to be_truthy
      expect(result.failure).to include 'contract_holder_sync_job required'
      expect(result.failure).to include 'primary hbx id'
      expect(result.failure).to include 'at least one of subscriber or responsible party policies required'
    end
  end

  context 'with valid params' do
    let!(:contract_holder_sync_job) { create(:contract_holder_sync_job) }
    let(:person) { FactoryBot.create(:person) }
    let(:subscriber_policies) { %w[55231212 42121212] }
    let(:responsible_party_policies) { %w[55231210 42121210] }

    let(:params) do
      {
        contract_holder_sync_job: contract_holder_sync_job,
        primary_person_hbx_id: person.authority_member_id,
        subscriber_policies: subscriber_policies,
        responsible_party_policies: responsible_party_policies
      }
    end

    let(:event_detail) do
      double(
        name: 'events.families.find_by_requested',
        payload: { person_hbx_id: person.authority_member_id }.to_json,
        publish: true
      )
    end

    context 'and new primary person' do
      before { @result = subject.call(params) }

      it 'return success' do
        expect(@result.success?).to be_truthy
      end

      it 'should create new subject' do
        expect(@result.success.class).to be DataStores::ContractHolderSubject
      end

      it 'should persist policies' do
        expect(@result.success.subscriber_policies).to eq subscriber_policies
        expect(@result.success.responsible_party_policies).to eq responsible_party_policies
      end
    end

    context 'and existing primary person' do
      let!(:contract_holder_subject) { subject.call(params.except(:responsible_party_policies)) }

      let(:updated_subscriber_policies) { %w[99231212 99121212] }
      let(:updated_responsible_party_policies) { %w[65231210 62121210] }

      let(:updated_params) do
        {
          contract_holder_sync_job: contract_holder_sync_job,
          primary_person_hbx_id: person.authority_member_id,
          subscriber_policies: updated_subscriber_policies,
          responsible_party_policies: updated_responsible_party_policies
        }
      end

      before { @result = subject.call(updated_params) }

      it 'return success' do
        expect(@result.success?).to be_truthy
      end

      it 'should return updated subject' do
        expect(@result.success.class).to be DataStores::ContractHolderSubject
      end

      it 'should not update subscriber policies' do
        expect(@result.success.subscriber_policies).to eq subscriber_policies
      end

      it 'should update responsible policies' do
        expect(@result.success.responsible_party_policies).to eq updated_responsible_party_policies
      end
    end
  end
end
