# frozen_string_literal: true

require 'shared_examples/cv3_family'

RSpec.describe InsurancePolicies::ContractHolders::CreateOrUpdate do
  subject { described_class.new }
  include_context 'cv3_family'

  it 'should fail if payload is invalid' do
    res = subject.call({ payload: {} })
    expect(res.failure).to be_truthy
  end

  context 'with valid parameters' do
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

    let(:current_payload) { family_params.to_h.to_json }

    let!(:ch_subject) do
      subject =
        contract_holder_sync_job.subjects.create(primary_person_hbx_id: '1000595', responsible_party_policies: ['1000'])
      subject.build_response_event(name: 'event.payload_requested', body: current_payload)
      subject.save
      subject
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

    let(:broker) { Broker.create! }

    let!(:policy) do
      Policy.create!(
        enrollment_group_id: '1000',
        plan: current_plan,
        kind: 'individual',
        aasm_state: 'terminated',
        hbx_enrollment_ids: ['1000'],
        broker_id: broker.id,
        responsible_party: ch_person.responsible_parties.first,
        carrier_id: carrier.id,
        enrollees: [enrollee]
      )
    end

    context 'initial load' do
      it 'should return success' do
        output = subject.call(subject: ch_subject)

        expect(output.success?).to be_truthy
        expect(InsurancePolicies::AcaIndividuals::IrsGroup.all.count).to eq(1)
        expect(InsurancePolicies::AcaIndividuals::IrsGroup.all.first.family_hbx_assigned_id).to eq family_params.to_h[
             :hbx_id
           ]
        expect(InsurancePolicies::InsuranceProduct.all.count).to eq(1)
        expect(InsurancePolicies::InsuranceProvider.all.count).to eq(1)
        expect(InsurancePolicies::AcaIndividuals::InsurancePolicy.all.count).to eq(1)
        expect(InsurancePolicies::AcaIndividuals::Enrollment.all.count).to eq(1)
        expect(InsurancePolicies::AcaIndividuals::TaxHouseholdGroup.all.count).to eq(1)
        expect(InsurancePolicies::AcaIndividuals::TaxHousehold.all.count).to eq(1)
        expect(InsurancePolicies::AcaIndividuals::TaxHouseholdMember.all.count).to eq(1)
        expect(InsurancePolicies::AcaIndividuals::EnrollmentsTaxHouseholds.all.count).to eq(1)
        expect(InsurancePolicies::AcaIndividuals::EnrolledMembersTaxHouseholdMembers.all.count).to eq(1)
      end
    end

    context 'updated enrollment information' do
      let(:current_payload) do
        family_payload = family_params.to_h
        family_payload[:households][0][:hbx_enrollments][0].tap do |enrollment|
          enrollment[:aasm_state] = 'coverage_terminated'
          enrollment[:total_premium] = 400.25
          enrollment[:applied_aptc_amount] = { cents: 28_951, currency_iso: 'USD' }
        end
        family_payload.to_json
      end
      it 'should update edidb enrollment' do
        output = subject.call(subject: ch_subject)

        expect(output.success?).to be_truthy
        expect(InsurancePolicies::AcaIndividuals::Enrollment.all.count).to eq(1)
        enrollment = InsurancePolicies::AcaIndividuals::Enrollment.first
        expect(enrollment.aasm_state).to eq 'coverage_terminated'
        expect(enrollment.total_premium_amount.to_f).to eq 400.25
        expect(enrollment.total_premium_adjustment_amount.to_f).to eq 289.51
      end
    end

    context 'when glue policy information got changed' do
      let(:contract_holder) do
        People::Person.create!(
          hbx_id: ch_person.authority_member_id,
          name: {
            first_name: ch_person.name_first,
            last_name: ch_person.name_last
          }
        )
      end

      let(:insurance_provider) { InsurancePolicies::InsuranceProvider.create!(hios_id: '33653', title: 'test') }
      let(:insurance_product) do
        InsurancePolicies::InsuranceProduct.create!(
          hios_plan_id: '33635ME12344',
          plan_year: policy.plan.year,
          insurance_provider: insurance_provider,
          coverage_type: policy.plan.coverage_type,
          name: policy.plan.name,
          market_type: policy.plan.market_type,
          metal_level: policy.plan.metal_level,
          ehb: policy.plan.ehb
        )
      end

      let(:insurance_agreement) do
        InsurancePolicies::InsuranceAgreement.create!(
          insurance_provider: insurance_provider,
          contract_holder: contract_holder
        )
      end

      let(:irs_group) { InsurancePolicies::AcaIndividuals::IrsGroup.create!(irs_group_id: '2200000001234567') }

      let!(:insurance_policy) do
        InsurancePolicies::AcaIndividuals::InsurancePolicy.create!(
          policy_id: policy.enrollment_group_id,
          insurance_product: insurance_product,
          insurance_agreement: insurance_agreement,
          aasm_state: 'submitted',
          start_on: Date.new(Date.today.year, 1, 1),
          irs_group: irs_group
        )
      end

      it 'should return success' do
        output = subject.call(subject: ch_subject)

        expect(output.success?).to be_truthy
        insurance_policy.reload
        expect(insurance_policy.aasm_state).to eq policy.aasm_state
        expect(insurance_policy.end_on).to eq policy.policy_end
      end
    end
  end
end
