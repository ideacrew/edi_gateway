# frozen_string_literal: true

require 'shared_examples/cv3_family'

RSpec.describe InsurancePolicies::SendFamilyPayload do
  subject { described_class.new }
  include_context 'cv3_family'

  context 'with invalid payload' do
    it 'return failure' do
      res = subject.call({})
      expect(res.failure?).to be_truthy
    end
  end

  context 'with valid params' do
    let(:contract_holder_sync_job) { create(:contract_holder_sync) }

    let!(:ch_person) do
      lookup_id = '1000595'
      person = Person.create(name_pfx: 'Mr', name_first: 'John', name_last: 'Adams')
      resp_party = ResponsibleParty.new(_id: 1, entity_identifier: 'parent')
      member = Member.new(hbx_member_id: lookup_id)
      person.members = [member]
      person.responsible_parties = [resp_party]
      person.save!
      person.update(authority_member_id: person.members.first.hbx_member_id)
      person
    end

    let(:past_enrollee) do
      Enrollee.new(
        m_id: ch_person.authority_member.hbx_member_id,
        rel_code: 'self',
        coverage_start: Date.new(Date.today.year - 1, 1, 1),
        coverage_end: Date.today.beginning_of_year - 1.day,
        cp_id: '12345'
      )
    end

    let(:enrollee) do
      Enrollee.new(
        m_id: ch_person.authority_member.hbx_member_id,
        rel_code: 'self',
        coverage_start: Date.new(Date.today.year, 1, 1),
        coverage_end: Date.today.end_of_month,
        cp_id: '12345'
      )
    end

    let(:past_plan) do
      Plan.create!(
        name: 'test_plan',
        hios_plan_id: '966667ME-01',
        carrier_id: carrier.id,
        coverage_type: 'health',
        metal_level: 'silver',
        market_type: 'individual',
        ehb: 1.0,
        year: Date.today.year - 1
      )
    end

    let(:current_plan) do
      Plan.create!(
        name: 'test_plan',
        hios_plan_id: '966667ME-01',
        carrier_id: carrier.id,
        coverage_type: 'health',
        metal_level: 'silver',
        market_type: 'individual',
        ehb: 1.0,
        year: Date.today.year
      )
    end

    let(:carrier) do
      carrier = Carrier.create!(name: 'test_carrier')
      carrier.carrier_profiles << CarrierProfile.new(id: 1, fein: '12345')
      carrier
    end

    let!(:policy) do
      Policy.create!(
        enrollment_group_id: '1002',
        plan: current_plan,
        kind: 'individual',
        aasm_state: 'terminated',
        hbx_enrollment_ids: ['1000'],
        responsible_party: ch_person.responsible_parties.first,
        carrier_id: carrier.id,
        enrollees: [enrollee]
      )
    end

    let!(:past_policy) do
      Policy.create!(
        enrollment_group_id: '1001',
        plan: past_plan,
        kind: 'individual',
        aasm_state: 'effectuated',
        hbx_enrollment_ids: ['1000'],
        responsible_party: ch_person.responsible_parties.first,
        carrier_id: carrier.id,
        enrollees: [past_enrollee]
      )
    end

    let(:current_payload) { family_params.to_h.to_json }

    let!(:ch_subject) do
      subject =
        contract_holder_sync_job.subjects.create(
          primary_person_hbx_id: '1000595',
          responsible_party_policies: %w[1001 1002]
        )
      subject.build_response_event(name: 'event.payload_requested', body: current_payload, status: :transmitted)
      subject.save
      subject
    end

    let(:cv3_payload) { double(success?: true, success: { payload: 'hello world!' }) }

    let(:params) { { sync_job_id: contract_holder_sync_job.job_id, primary_person_hbx_id: '1000595' } }

    context 'when subject primary person hbx id passed' do
      before do
        allow(subject).to receive(:build_cv_payload_with).and_return(cv3_payload)
        @result = subject.call(params)
      end

      it 'return success' do
        expect(@result.success?).to be_truthy
      end

      it 'should create transmit events by calendar year' do
        output = @result.success
        expect(output.transmit_events.count).to eq 2
        output.transmit_events.each do |event|
          expect(event.transmitted?).to be_truthy
          expect(event.name).to eq 'events.insurance_policies.posted'
          headers = JSON.parse(event.headers, symbolize_names: true)
          expect(headers[:correlation_id]).to be_present
          expect(headers[:assistance_year]).to be_present
          if headers[:assistance_year] == Date.today.year - 1
            expect(headers[:affected_policies]).to eq [past_policy.enrollment_group_id]
          else
            expect(headers[:affected_policies]).to eq [policy.enrollment_group_id]
          end
        end
      end
    end

    context 'when cv3 family build errored' do
      let(:failure_double) { double(success?: false) }

      before { allow(subject).to receive(:build_cv_payload_with).and_return(failure_double) }

      it 'should create transmit events with errors' do
        result = subject.call(params)
        expect(result.success?).to be_falsey
        ch_subject.reload
        expect(ch_subject.transmit_events.count).to eq 2
        ch_subject.transmit_events.each do |event|
          expect(event.errored?).to be_truthy
          expect(event.name).to eq 'events.insurance_policies.posted'
          headers = JSON.parse(event.headers, symbolize_names: true)
          expect(headers[:correlation_id]).to be_present
          expect(headers[:assistance_year]).to be_present
          expect(event.error_messages).to include("cv3 family payload errored for #{past_policy.enrollment_group_id}")
          expect(event.error_messages).to include("cv3 family payload errored for #{policy.enrollment_group_id}")
        end
      end
    end
  end
end
