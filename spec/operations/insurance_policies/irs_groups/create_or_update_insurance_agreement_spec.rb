# frozen_string_literal: true

# # frozen_string_literal: true

require 'shared_examples/cv3_family'

RSpec.describe IrsGroups::CreateOrUpdateInsuranceAgreement do
  subject { described_class.new }
  include_context 'cv3_family'

  context 'with invalid payload' do
    it 'return failure' do
      res = subject.call({})
      expect(res.failure?).to be_truthy
    end
  end

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

  let(:contract_holder) { People::Person.create!(hbx_id: ch_person.authority_member_id) }

  let(:irs_group) { InsurancePolicies::AcaIndividuals::IrsGroup.create!(irs_group_id: '2200000001234567') }

  let(:carrier) do
    carrier = Carrier.create!(name: 'test_carrier')
    carrier_profile = CarrierProfile.new(id: 1, fein: '12345')
    carrier.carrier_profiles << carrier_profile
    carrier
  end

  let(:enrollee) do
    Enrollee.new(
      m_id: ch_person.authority_member.hbx_member_id,
      rel_code: 'self',
      coverage_start: Date.new(Date.today.year, 1, 1),
      cp_id: '12345'
    )
  end

  let(:plan) do
    Plan.create!(
      name: 'test_plan',
      hios_plan_id: '966667ME-01',
      carrier_id: carrier.id,
      coverage_type: 'health',
      year: Date.today.year,
      metal_level: 'sliver',
      market_type: 'individual'
    )
  end

  let!(:policy) do
    Policy.create!(
      enrollment_group_id: '1000',
      plan: plan,
      kind: 'individual',
      aasm_state: 'submitted',
      hbx_enrollment_ids: ['1000'],
      responsible_party: ch_person.responsible_parties.first,
      carrier_id: carrier.id,
      enrollees: [enrollee]
    )
  end

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

  let(:contract_holder_hash) { contract_holder.as_json(include: %i[addresses emails phones name]).deep_symbolize_keys }

  context 'with valid payload' do
    let(:valid_params) do
      { contract_holder_hash: contract_holder_hash, irs_group_hash: irs_group.to_hash, policy: policy }
    end

    before { @result = subject.call(valid_params) }

    it 'return success' do
      expect(@result.success?).to be_truthy
    end
  end
end
