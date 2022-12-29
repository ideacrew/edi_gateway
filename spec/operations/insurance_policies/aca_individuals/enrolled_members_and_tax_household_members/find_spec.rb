# frozen_string_literal: true

require 'shared_examples/cv3_family'

RSpec.describe InsurancePolicies::AcaIndividuals::EnrolledMembersAndTaxHouseholdMembers::Find do
  subject { described_class.new }
  include_context 'cv3_family'

  let!(:enr_members_thhm) { FactoryBot.create(:enrolled_members_tax_household_members) }

  context 'with invalid payload' do
    it "return failure" do
      res = subject.call({ scope_name: :by_person_hbx_id,
                           person_hbx_id: ""})
      expect(res.failure?).to be_truthy
    end
  end

  context 'with valid payload' do
    it "return success" do
      res = subject.call({ scope_name: :by_person_hbx_id,
                           person_hbx_id: enr_members_thhm.person.hbx_id })
      expect(res.success?).to be_truthy
    end

    it "return object hash" do
      res = subject.call({ scope_name: :by_person_hbx_id,
                           person_hbx_id: enr_members_thhm.person.hbx_id})
      expect(res.success.class).to be Hash
    end
  end
end
