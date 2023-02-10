# frozen_string_literal: true

RSpec.describe DataStores::ContractHolderSubjects::CreateOrUpdate do
  subject { described_class.new }

  context 'with invalid params' do
    it "return failure" do
      result = subject.call({})
      expect(result.failure?).to be_truthy
      expect(result.failure).to include "contract_holder_sync_job required"
      expect(result.failure).to include "primary hbx id"
      expect(result.failure).to include "at least one of subscriber or responsible party policies required"
    end
  end

  context 'with valid params' do
    let!(:contract_holder_sync_job) { create(:contract_holder_sync_job) }
    let(:person) { FactoryBot.create(:person) }
    let(:subscriber_policies) { ['55231212', '42121212'] }
    let(:responsible_party_policies) { ['55231210', '42121210'] }

    let(:params) do
      {
        contract_holder_sync_job: contract_holder_sync_job,
        primary_person_hbx_id: person.authority_member_id,
        subscriber_policies: subscriber_policies,
        responsible_party_policies: responsible_party_policies
      }
    end

    let(:request_event) do
      double(name: 'events.families.find_by_requested', payload: "hello world!!", publish: true)
    end

    before do
      allow(subject).to receive(:event).and_return(request_event)
    end

    context 'and new primary person' do
      before do
        @result = subject.call(params)
      end

      it "return success" do
        expect(@result.success?).to be_truthy
      end

      it "should create new subject" do
        expect(@result.success.class).to be DataStores::ContractHolderSubject
      end

      it "should persist policies" do
        expect(@result.success.subscriber_policies).to eq subscriber_policies
        expect(@result.success.responsible_party_policies).to eq responsible_party_policies
      end

      it "should store request event" do
        request_event_instance = @result.success.request_event

        expect(request_event_instance).to be_present
        expect(request_event_instance.name).to eq request_event.name
        expect(request_event_instance.body).to eq request_event.payload
      end
    end

    context 'and existing primary person' do
      let!(:contract_holder_subject) { subject.call(params.except(:responsible_party_policies)) }

      let(:updated_subscriber_policies) { ['99231212', '99121212'] }
      let(:updated_responsible_party_policies) { ['65231210', '62121210'] }

      let(:updated_params) do
        {
          contract_holder_sync_job: contract_holder_sync_job,
          primary_person_hbx_id: person.authority_member_id,
          subscriber_policies: updated_subscriber_policies,
          responsible_party_policies: updated_responsible_party_policies
        }
      end

      before do
        @result = subject.call(updated_params)
      end

      it "return success" do
        expect(@result.success?).to be_truthy
      end

      it "should return updated subject" do
        expect(@result.success.class).to be DataStores::ContractHolderSubject
      end

      it "should not update subscriber policies" do
        expect(@result.success.subscriber_policies).to eq subscriber_policies
      end

      it "should update responsible policies" do
        expect(@result.success.responsible_party_policies).to eq updated_responsible_party_policies
      end
    end
  end
end
