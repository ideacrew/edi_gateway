# frozen_string_literal: true

RSpec.describe DataStores::ContractHolderSyncJobs::ProcessResponseEvent do
  subject { described_class.new }

  context 'with invalid params' do
    it 'return failure' do
      result = subject.call({})
      expect(result.failure?).to be_truthy
      expect(result.failure).to include 'correlation_id is required'
      expect(result.failure).to include 'primary_person_hbx_id is required'
      expect(result.failure).to include 'family is required'
      expect(result.failure).to include 'event_name is required'
    end
  end

  context 'with valid params' do
    let!(:contract_holder_sync_job) { create(:contract_holder_sync) }
    let!(:contract_holder_subject) do
      create(
        :contract_holder_subject,
        contract_holder_sync: contract_holder_sync_job,
        primary_person_hbx_id: person.authority_member_id,
        subscriber_policies: subscriber_policies,
        responsible_party_policies: responsible_party_policies
      )
    end

    let(:person) { FactoryBot.create(:person) }
    let(:subscriber_policies) { %w[55231212 42121212] }
    let(:responsible_party_policies) { %w[55231210 42121210] }

    let(:params) do
      {
        correlation_id: contract_holder_sync_job.job_id,
        primary_person_hbx_id: person.authority_member_id,
        family: {},
        event_name: 'events.enroll.families.found_by'
      }
    end

    let(:success_double) { double(success?: true) }
    let(:failure_double) { double(success?: false, failure: double(errors: ['failed!'])) }

    let(:service_instance) { InsurancePolicies::ContractHolders::CreateOrUpdate.new }
    context 'on successful processing of db updates' do
      before do
        allow_any_instance_of(described_class).to receive(:contract_holder_update_service).and_return(service_instance)
        allow(service_instance).to receive(:call).with(subject: contract_holder_subject).and_return(success_double)

        @result = subject.call(params)
      end

      it 'return success' do
        expect(@result.success?).to be_truthy
      end

      it 'should create response event' do
        expect(@result.success.class).to be Integrations::Event
        response_event = contract_holder_subject.reload.response_event

        expect(response_event).to be_present
        expect(response_event.transmitted?).to be_truthy
        expect(response_event.name).to eq 'events.enroll.families.found_by'
      end
    end

    context 'on failure to process db updates' do
      before do
        allow_any_instance_of(described_class).to receive(:contract_holder_update_service).and_return(service_instance)
        allow_any_instance_of(described_class).to receive(:error_messages).and_return(failure_double.failure.errors)
        allow(service_instance).to receive(:call).with(subject: contract_holder_subject).and_return(failure_double)

        @result = subject.call(params)
      end

      context 'with failed contract_holder_update' do
        it 'return failure' do
          expect(@result.failure?).to be_truthy
        end

        it 'should create response event with errors' do
          expect(@result.failure.class).to be Integrations::Event
          response_event = contract_holder_subject.reload.response_event

          expect(response_event).to be_present
          expect(response_event.errored?).to be_truthy
          expect(response_event.error_messages).to eq failure_double.failure.errors
          expect(response_event.name).to eq 'events.enroll.families.found_by'
        end
      end

      context 'with family CV errors' do
        let(:params) do
          {
            correlation_id: contract_holder_sync_job.job_id,
            errors: ['Unable to find person with hbx_id: person_hbx_id'],
            event_name: 'events.enroll.families.found_by',
            family: {},
            primary_person_hbx_id: person.authority_member_id
          }
        end
        let(:response_event) { contract_holder_subject.reload.response_event }

        it 'return failure' do
          expect(@result.failure?).to be_truthy
        end

        it 'should create response event with errors' do
          expect(@result.failure).to eq(
            "Errors #{params[:errors]} in generating Family CV in Enroll for subject with primary_person_hbx_id: #{
              response_event.eventable.primary_person_hbx_id}"
          )
          expect(response_event).to be_present
          expect(response_event.errored?).to be_truthy
          expect(response_event.error_messages).to eq(params[:errors])
          expect(response_event.name).to eq 'events.enroll.families.found_by'
        end
      end
    end
  end
end
