# frozen_string_literal: true

require 'shared_examples/cv3_family'

RSpec.describe InsurancePolicies::AcaIndividuals::Enrollments::Create do
  subject { described_class.new }
  include_context 'cv3_family'

  let!(:hbx_enrollment) { hbx_enrollments.first }
  let!(:insurance_policy) do
    FactoryBot.create(:insurance_policy)
  end

  let(:params) do
    {
      hbx_id: hbx_enrollment[:hbx_id],
      effective_on: hbx_enrollment[:effective_on],
      aasm_state: hbx_enrollment[:aasm_state],
      terminated_on: hbx_enrollment[:terminated_on],
      market_place_kind: hbx_enrollment[:market_place_kind],
      enrollment_period_kind: hbx_enrollment[:enrollment_period_kind],
      product_kind: hbx_enrollment[:product_kind],
      applied_aptc_amount: hbx_enrollment[:applied_aptc_amount],
      total_premium: hbx_enrollment[:total_premium],
      hbx_enrollment_members: hbx_enrollment[:hbx_enrollment_members],
      product_reference: hbx_enrollment[:product_reference],
      issuer_profile_reference: hbx_enrollment[:issuer_profile_reference],
      insurance_policy: insurance_policy.as_json.deep_symbolize_keys
    }
  end

  context 'with invalid payload' do
    it "return failure" do
      result = subject.call({})
      expect(result.failure?).to be_truthy
    end
  end

  context 'with valid payload' do
    before do
      @result = subject.call(params)
    end

    it "return success" do
      expect(@result.success?).to be_truthy
    end

    it "return hash" do
      expect(@result.success.class).to be Hash
    end

    it "should have hbx_id" do
      expect(@result.success[:hbx_id]).to eq params[:hbx_id]
    end
  end
end
