# frozen_string_literal: true

require 'shared_examples/cv3_family'

RSpec.describe InsurancePolicies::Refresh do
  subject { described_class.new }
  include_context 'cv3_family'

  context 'with invalid payload' do
    it 'return failure' do
      res = subject.call({})
      expect(res.failure?).to be_truthy
    end

    context 'when inclusion list passed' do
      it 'return source_job_id required error' do
        res = subject.call({
                             start_time: Time.now,
                             end_time: Time.now + 1.hour,
                             inclusion_policies: ['332323']
                           })

        expect(res.failure).to eq('source_job_id is required')
      end
    end
  end

  context 'with valid params' do
    let(:start_time) { 12.hours.ago }
    let(:end_time) { Time.now }
    let(:params) { { start_time: start_time, end_time: end_time } }

    let(:people_coverages) do
      {
        '1030800' => {
          'subscriber_policies' => ['1190331'],
          'responsible_party_policies' => []
        },
        '1025123' => {
          'subscriber_policies' => %w[1461616 1191217],
          'responsible_party_policies' => ['1495008']
        },
        '1224990' => {
          'subscriber_policies' => [],
          'responsible_party_policies' => %w[1605982 1521441]
        }
      }
    end

    let(:subscriber_policies) do
      people_coverages.collect do |hbx_id, coverages|
        { '_id' => hbx_id, 'enrolled_policies' => coverages['subscriber_policies'] } if coverages['subscriber_policies'].present?
      end.compact
    end

    let(:responsible_party_policies) do
      people_coverages.collect do |hbx_id, coverages|
        if coverages['responsible_party_policies'].present?
          { '_id' => hbx_id, 'enrolled_policies' => coverages['responsible_party_policies'] }
        end
      end.compact
    end

    before do
      allow(subject).to receive(:responsible_party_person_for)
        .with('1025123')
        .and_return(double(authority_member_id: '1025123'))
      allow(subject).to receive(:responsible_party_person_for)
        .with('1224990')
        .and_return(double(authority_member_id: '1224990'))
      allow_any_instance_of(InsurancePolicies::GluePolicyQuery).to receive(:group_by_subscriber_query).and_return(
        subscriber_policies
      )
      allow_any_instance_of(InsurancePolicies::GluePolicyQuery).to receive(:group_by_responsible_party_query)
        .and_return(responsible_party_policies)
    end

    context 'when valid time range passed' do
      before { @result = subject.call(params) }

      it 'return success' do
        expect(@result.success?).to be_truthy
      end

      it 'should create new contract holder sync job' do
        output = @result.success
        expect(output.class).to be DataStores::ContractHolderSyncJob
        expect(output.time_span_start.utc).to eq start_time.utc
        expect(output.time_span_end.utc).to eq end_time.utc
        expect(output.status).to eq :transmitted
        expect(output.job_id).to be_present
      end

      it 'should create contract holder subjects with policies' do
        output = @result.success
        expect(output.subjects.count).to eq 3

        people_coverages.each do |hbx_id, coverages|
          subject = output.subjects.by_primary_hbx_id(hbx_id).first
          expect(subject.subscriber_policies).to eq coverages['subscriber_policies']
          expect(subject.responsible_party_policies).to eq coverages['responsible_party_policies']
          expect(subject.request_event).to be_present
          expect(subject.request_event.name).to eq 'events.families.find_by_requested'
        end
      end

      it 'should not have any errors' do
        expect(subject.error_handler.error_messages).to be_empty
      end
    end
  end
end
