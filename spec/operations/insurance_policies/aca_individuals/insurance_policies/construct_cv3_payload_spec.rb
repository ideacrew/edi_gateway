# frozen_string_literal: true

require './spec/shared_examples/insurance_policies/shared_insurance_policies'

RSpec.describe InsurancePolicies::AcaIndividuals::InsurancePolicies::ConstructCv3Payload do
  include_context 'shared_insurance_policies'

  before do
    DatabaseCleaner.clean
  end

  let(:subscriber_person) { FactoryBot.create(:people_person) }
  let(:dependent_person) { FactoryBot.create(:people_person) }
  let!(:glue_subscriber_person) { FactoryBot.create(:person, authority_member_id: subscriber_person.hbx_id) }
  let!(:glue_dependent_person) { FactoryBot.create(:person, authority_member_id: dependent_person.hbx_id) }
  let(:another_dependent_person) { FactoryBot.create(:people_person) }
  let(:year) { Date.today.year }
  let(:insurance_policy) { FactoryBot.create(:insurance_policy, start_on: Date.new(year, 1, 1), end_on: Date.new(year, 12, 31)) }
  let(:subscriber) { FactoryBot.build(:enrolled_member, person: subscriber_person) }
  let(:dependents) { FactoryBot.build(:enrolled_member, person: dependent_person) }
  let!(:enrollment_1) do
    FactoryBot.create(:enrollment, start_on: Date.new(year, 1, 1),
                                   effectuated_on: Date.new(year, 1, 1),
                                   end_on: Date.new(year, 12, 31), insurance_policy: insurance_policy,
                                   subscriber: subscriber,
                                   dependents: [dependents])
  end
  let!(:premium_schedule_1) { FactoryBot.create(:premium_schedule, enrolled_member: enrollment_1.subscriber) }
  let!(:premium_schedule_2) { FactoryBot.create(:premium_schedule, enrolled_member: enrollment_1.dependents.first) }
  let!(:uqhp_tax_household) { FactoryBot.create(:tax_household, is_aqhp: false) }
  let!(:uqhp_tax_household_member_1) do
    FactoryBot.create(:tax_household_member, tax_household: uqhp_tax_household, person: subscriber_person,
                                             is_tax_filer: true)
  end
  let!(:uqhp_tax_household_member_2) do
    FactoryBot.create(:tax_household_member, tax_household: uqhp_tax_household, person: dependent_person,
                                             is_tax_filer: true)
  end

  let!(:aqhp_tax_household_1) { FactoryBot.create(:tax_household, is_aqhp: true) }
  let!(:aqhp_tax_household_2) { FactoryBot.create(:tax_household, is_aqhp: true) }

  let!(:aqhp_tax_household_member_1) do
    FactoryBot.create(:tax_household_member, tax_household: aqhp_tax_household_1, person: subscriber_person,
                                             is_tax_filer: true)
  end
  let!(:aqhp_tax_household_member_2) do
    FactoryBot.create(:tax_household_member, tax_household: aqhp_tax_household_2, person: dependent_person,
                                             is_tax_filer: true)
  end

  let!(:uqhp_enrollment_tax_household) do
    FactoryBot.create(:enrollments_tax_households, enrollment_id: enrollment_1.id, tax_household_id: uqhp_tax_household.id)
  end

  let!(:aqhp_enrollment_tax_household_1) do
    FactoryBot.create(:enrollments_tax_households, enrollment_id: enrollment_1.id, tax_household_id: aqhp_tax_household_1.id)
  end

  let!(:aqhp_enrollment_tax_household_2) do
    FactoryBot.create(:enrollments_tax_households, enrollment_id: enrollment_1.id, tax_household_id: aqhp_tax_household_2.id)
  end

  context "with valid input params" do
    it "should return success" do
      expect(subject.call({ insurance_policy: insurance_policy }).success?).to be_truthy
    end

    it "should not return duplicate people in a tax household" do
      result = subject.call({ insurance_policy: insurance_policy }).value!
      expect(result[:aptc_csr_tax_households].length).to eq 2
      expect(result[:aptc_csr_tax_households].first[:covered_individuals].length).to eq 1
      expect(result[:aptc_csr_tax_households].second[:covered_individuals].length).to eq 1
    end
  end
end
