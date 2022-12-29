# frozen_string_literal: true

require 'shared_examples/cv3_family'

RSpec.describe InsurancePolicies::AcaIndividuals::EnrolledMembersAndTaxHouseholdMembers::Create do
  subject { described_class.new }
  include_context 'cv3_family'

  let!(:person_hash) { person }
  let!(:thh_hash) { tax_households.first }
  let!(:person_persisted) do
    FactoryBot.create(:person,  hbx_id: person_hash[:hbx_id])
  end
  let!(:enr_thh) { FactoryBot.create(:enrollments_tax_households) }

  context 'with invalid payload' do
    it "return failure" do
      result = subject.call({})
      expect(result.failure?).to be_truthy
    end
  end

  context 'with valid payload' do
    before do
      tax_household_member_enrollment_member.merge!(person: person_persisted.as_json.deep_symbolize_keys)
      tax_household_member_enrollment_member.merge!(enrollment_tax_household: enr_thh.as_json.deep_symbolize_keys)

      @result = subject.call(tax_household_member_enrollment_member)
    end

    it "return success" do
      expect(@result.success?).to be_truthy
    end

    it "return hash" do
      expect(@result.success.class).to be Hash
    end

    it "should have tax_household_id" do
      expect(@result.success[:enrollments_tax_households_id]).to eq enr_thh.id
    end
  end
end
