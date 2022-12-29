# frozen_string_literal: true

require 'shared_examples/cv3_family'

RSpec.describe InsurancePolicies::AcaIndividuals::EnrollmentsAndTaxHouseholds::Create do
  subject { described_class.new }
  include_context 'cv3_family'
  let!(:enr_hash) {hbx_enrollments.first}
  let!(:thh_hash) {tax_households.first}
  let!(:enr) {FactoryBot.create(:enrollment, hbx_id: enr_hash[:hbx_id], total_premium_amount: enr_hash[:total_premium])}
  let!(:thh) {FactoryBot.create(:tax_household, hbx_id: thh_hash[:hbx_id])}

  context 'with invalid payload' do
    it "return failure" do
      res = subject.call({ tax_household: {}, enrollment: {} })
      expect(res.failure?).to be_truthy
    end
  end

  context 'with valid payload' do
    before do
      enr_hash.merge!(id: enr.id)
      thh_hash.merge!(id: thh.id)
      @res = subject.call(tax_households_references_params.merge(tax_household: tax_households.first, enrollment: hbx_enrollments.first ))
    end

    it "return success" do
      expect(@res.success?).to be_truthy
    end

    it "return hash" do
      expect(@res.success.class).to be Hash
    end

    it "should have tax_household_id" do
      expect(@res.success[:tax_household_id]).to eq thh.id
    end

    it "should have enrollment_id" do
      expect(@res.success[:enrollment_id]).to eq enr.id
    end
  end
end
