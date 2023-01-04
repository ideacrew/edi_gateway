# frozen_string_literal: true

require 'shared_examples/cv3_family'

RSpec.describe InsurancePolicies::AcaIndividuals::InsurancePolicies::Create do
  subject { described_class.new }
  include_context 'cv3_family'

  context 'with invalid payload' do
    it "return failure" do
      res = subject.call({})
      expect(res.failure?).to be_truthy
    end
  end

  context 'with valid payload' do
    let!(:hbx_enrollment) { hbx_enrollments.first }
    let!(:hbx_enrollment_members) { hbx_enrollments.first[:hbx_enrollment_members] }

    let!(:policy) do
      FactoryBot.create(:policy)
    end

    let!(:enrollees) do
      hbx_enrollment_members.collect do |member|
        FactoryBot.create(:enrollee, policy: policy, m_id: member[:family_member_reference][:family_member_hbx_id])
      end
    end

    let!(:insurance_agreement) do
      FactoryBot.create(:insurance_agreement)
    end

    let!(:insurance_product) do
      FactoryBot.create(:insurance_product)
    end

    let!(:irs_group) do
      FactoryBot.create(:irs_group)
    end

    let!(:params) do
      { start_on: policy.policy_start, end_on: policy.policy_end,
        policy_id: "1234",
        hbx_enrollment_ids: ['1234', '4321'],
        aasm_state: 'coverage_selected',
        carrier_policy_id: policy.subscriber.cp_id }
    end

    before do
      params.merge!(insurance_agreement: insurance_agreement.as_json.deep_symbolize_keys)
      params.merge!(insurance_product: { name: insurance_product.name, hios_plan_id: insurance_product.hios_plan_id, plan_year: insurance_product.plan_year,
                                         coverage_type: insurance_product.coverage_type, metal_level: insurance_product.metal_level,
                                         market_type: insurance_product.market_type, ehb: insurance_product.ehb })
      params.merge!(irs_group: irs_group.as_json.deep_symbolize_keys)
      @result = subject.call(params)
    end

    it "return success" do
      expect(@result.success?).to be_truthy
    end

    it "return hash" do
      expect(@result.success.class).to be Hash
    end

    it "should have irs_group_id" do
      expect(@result.success[:irs_group_id]).to eq irs_group.id
    end
  end
end
