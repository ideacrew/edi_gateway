# frozen_string_literal: true

require './spec/shared_examples/insurance_policies/shared_insurance_policies'

RSpec.describe InsurancePolicies::AcaIndividuals::InsurancePolicies::ConstructCv3Payload do
  include_context 'shared_insurance_policies'

  before :each do
    DatabaseCleaner.clean
  end

  after :each do
    DatabaseCleaner.clean
  end

  let(:subscriber_person) { FactoryBot.create(:people_person) }
  let(:dependent_person) { FactoryBot.create(:people_person) }
  let(:another_dependent_person) { FactoryBot.create(:people_person) }
  let!(:glue_subscriber_person) { FactoryBot.create(:person, authority_member_id: subscriber_person.hbx_id) }
  let!(:glue_dependent_person) { FactoryBot.create(:person, authority_member_id: dependent_person.hbx_id) }
  let!(:glue_dependent_person_2) { FactoryBot.create(:person, authority_member_id: another_dependent_person.hbx_id) }
  let(:year) { Date.today.year }
  let(:insurance_policy) { FactoryBot.create(:insurance_policy, start_on: Date.new(year, 1, 1), end_on: Date.new(year, 12, 31)) }
  let(:subscriber) { FactoryBot.build(:enrolled_member, person: subscriber_person) }
  let(:dependents) { FactoryBot.build(:enrolled_member, person: dependent_person) }

  context "with valid input params" do
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

    let!(:enrollment_1) do
      FactoryBot.create(:enrollment, start_on: Date.new(year, 1, 1),
                                     effectuated_on: Date.new(year, 1, 1),
                                     end_on: Date.new(year, 12, 31), insurance_policy: insurance_policy,
                                     subscriber: subscriber,
                                     dependents: [dependents])
    end
    let!(:premium_schedule_1) { FactoryBot.create(:premium_schedule, enrolled_member: enrollment_1.subscriber) }
    let!(:premium_schedule_2) { FactoryBot.create(:premium_schedule, enrolled_member: enrollment_1.dependents.first) }

    let!(:aqhp_enrollment_tax_household_1) do
      FactoryBot.create(:enrollments_tax_households, enrollment_id: enrollment_1.id, tax_household_id: aqhp_tax_household_1.id)
    end

    let!(:aqhp_enrollment_tax_household_2) do
      FactoryBot.create(:enrollments_tax_households, enrollment_id: enrollment_1.id, tax_household_id: aqhp_tax_household_2.id)
    end

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

  context "member moved out of a tax_household as a new tax_filer during mid coverage" do
    let(:enrollment_1_subscriber) { FactoryBot.build(:enrolled_member, person: subscriber_person) }
    let(:enrollment_1_dependents) { FactoryBot.build(:enrolled_member, person: dependent_person) }

    let(:enrollment_2_subscriber) { FactoryBot.build(:enrolled_member, person: subscriber_person) }
    let(:enrollment_2_dependents) { FactoryBot.build(:enrolled_member, person: dependent_person) }
    let!(:enrollment_1) do
      FactoryBot.create(:enrollment, start_on: Date.new(year, 1, 1),
                                     effectuated_on: Date.new(year, 1, 1),
                                     created_at: Time.now,
                                     end_on: Date.new(year, 5, 31), insurance_policy: insurance_policy,
                                     subscriber: enrollment_1_subscriber,
                                     dependents: [enrollment_1_dependents])
    end

    let!(:enrollment_2) do
      FactoryBot.create(:enrollment, start_on: Date.new(year, 6, 1),
                                     effectuated_on: Date.new(year, 6, 1),
                                     created_at: Time.now + 10.minutes,
                                     end_on: Date.new(year, 12, 31), insurance_policy: insurance_policy,
                                     subscriber: enrollment_2_subscriber,
                                     dependents: [enrollment_2_dependents])
    end
    let!(:premium_schedule_1_enrollment_1) { FactoryBot.create(:premium_schedule, enrolled_member: enrollment_1.subscriber) }
    let!(:premium_schedule_2_enrollment_1) do
      FactoryBot.create(:premium_schedule, enrolled_member: enrollment_1.dependents.first)
    end
    let!(:premium_schedule_1_enrollment_2) { FactoryBot.create(:premium_schedule, enrolled_member: enrollment_2.subscriber) }
    let!(:premium_schedule_2_enrollment_2) do
      FactoryBot.create(:premium_schedule, enrolled_member: enrollment_2.dependents.first)
    end
    let!(:aqhp_tax_household_1) { FactoryBot.create(:tax_household, is_aqhp: true) }
    let!(:aqhp_tax_household_2) { FactoryBot.create(:tax_household, is_aqhp: true) }
    let!(:aqhp_tax_household_3) { FactoryBot.create(:tax_household, is_aqhp: true) }

    let!(:aqhp_thh_1_sub_tax_household_member) do
      FactoryBot.create(:tax_household_member, tax_household: aqhp_tax_household_1, person: subscriber_person,
                                               is_tax_filer: true)
    end
    let!(:aqhp_thh_1_dep_tax_household_member) do
      FactoryBot.create(:tax_household_member, tax_household: aqhp_tax_household_1, person: dependent_person,
                                               is_tax_filer: false)
    end

    let!(:aqhp_thh_2_sub_tax_household_member) do
      FactoryBot.create(:tax_household_member, tax_household: aqhp_tax_household_2, person: subscriber_person,
                                               is_tax_filer: true)
    end

    let!(:aqhp_thh_3_dep_tax_household_member) do
      FactoryBot.create(:tax_household_member, tax_household: aqhp_tax_household_3, person: dependent_person,
                                               is_tax_filer: true)
    end

    let!(:aqhp_enrollment_tax_household_1) do
      FactoryBot.create(:enrollments_tax_households, enrollment_id: enrollment_1.id, tax_household_id: aqhp_tax_household_1.id)
    end

    let!(:aqhp_enrollment_tax_household_2) do
      FactoryBot.create(:enrollments_tax_households, enrollment_id: enrollment_2.id, tax_household_id: aqhp_tax_household_2.id)
    end

    let!(:aqhp_enrollment_tax_household_3) do
      FactoryBot.create(:enrollments_tax_households, enrollment_id: enrollment_2.id, tax_household_id: aqhp_tax_household_3.id)
    end

    it "should return 2 tax_households with correct member coverage dates" do
      result = subject.call({ insurance_policy: insurance_policy })
      expect(result.success?).to be_truthy
      result = result.value!
      expect(result[:aptc_csr_tax_households].length).to eq 2
      expect(result[:aptc_csr_tax_households].first[:covered_individuals].length).to eq 2
      expect(result[:aptc_csr_tax_households].first[:covered_individuals][0][:coverage_start_on]).to eq enrollment_1.start_on
      expect(result[:aptc_csr_tax_households].first[:covered_individuals][0][:coverage_end_on]).to eq enrollment_2.end_on
      expect(result[:aptc_csr_tax_households].first[:covered_individuals][1][:coverage_start_on]).to eq enrollment_1.start_on
      expect(result[:aptc_csr_tax_households].first[:covered_individuals][1][:coverage_end_on]).to eq enrollment_1.end_on

      expect(result[:aptc_csr_tax_households].second[:covered_individuals].length).to eq 1
      expect(result[:aptc_csr_tax_households].second[:covered_individuals][0][:coverage_start_on]).to eq enrollment_2.start_on
      expect(result[:aptc_csr_tax_households].second[:covered_individuals][0][:coverage_end_on]).to eq enrollment_2.end_on
    end
  end

  context "member moved into a tax_household as a dependent during mid coverage" do
    let!(:enrollment_1) do
      FactoryBot.create(:enrollment, start_on: Date.new(year, 1, 1),
                                     effectuated_on: Date.new(year, 1, 1),
                                     end_on: Date.new(year, 5, 31), insurance_policy: insurance_policy,
                                     subscriber: subscriber,
                                     dependents: [dependents])
    end
    let!(:enrollment_2) do
      FactoryBot.create(:enrollment, start_on: Date.new(year, 6, 1),
                                     effectuated_on: Date.new(year, 6, 1),
                                     end_on: Date.new(year, 12, 31), insurance_policy: insurance_policy,
                                     subscriber: subscriber,
                                     dependents: [dependents])
    end
    let!(:premium_schedule_1_enrollment_1) { FactoryBot.create(:premium_schedule, enrolled_member: enrollment_1.subscriber) }
    let!(:premium_schedule_2_enrollment_1) do
      FactoryBot.create(:premium_schedule, enrolled_member: enrollment_1.dependents.first)
    end
    let!(:premium_schedule_1_enrollment_2) { FactoryBot.create(:premium_schedule, enrolled_member: enrollment_2.subscriber) }
    let!(:premium_schedule_2_enrollment_2) do
      FactoryBot.create(:premium_schedule, enrolled_member: enrollment_2.dependents.first)
    end
    let!(:aqhp_tax_household_1) { FactoryBot.create(:tax_household, is_aqhp: true) }
    let!(:aqhp_tax_household_2) { FactoryBot.create(:tax_household, is_aqhp: true) }
    let!(:aqhp_tax_household_3) { FactoryBot.create(:tax_household, is_aqhp: true) }

    let!(:aqhp_thh_1_sub_tax_household_member) do
      FactoryBot.create(:tax_household_member, tax_household: aqhp_tax_household_1, person: subscriber_person,
                                               is_tax_filer: true)
    end
    let!(:aqhp_thh_2_dep_tax_household_member) do
      FactoryBot.create(:tax_household_member, tax_household: aqhp_tax_household_2, person: dependent_person,
                                               is_tax_filer: false)
    end

    let!(:aqhp_thh_3_sub_tax_household_member) do
      FactoryBot.create(:tax_household_member, tax_household: aqhp_tax_household_3, person: subscriber_person,
                                               is_tax_filer: true)
    end

    let!(:aqhp_thh_3_dep_tax_household_member) do
      FactoryBot.create(:tax_household_member, tax_household: aqhp_tax_household_3, person: dependent_person,
                                               is_tax_filer: true)
    end

    let!(:aqhp_enrollment_tax_household_1) do
      FactoryBot.create(:enrollments_tax_households, enrollment_id: enrollment_1.id, tax_household_id: aqhp_tax_household_1.id)
    end

    let!(:aqhp_enrollment_tax_household_2) do
      FactoryBot.create(:enrollments_tax_households, enrollment_id: enrollment_1.id, tax_household_id: aqhp_tax_household_2.id)
    end

    let!(:aqhp_enrollment_tax_household_3) do
      FactoryBot.create(:enrollments_tax_households, enrollment_id: enrollment_2.id, tax_household_id: aqhp_tax_household_3.id)
    end

    it "should return 2 tax_households with correct member coverage dates" do
      result = subject.call({ insurance_policy: insurance_policy })
      expect(result.success?).to be_truthy
      result = result.value!
      expect(result[:aptc_csr_tax_households].length).to eq 2
      expect(result[:aptc_csr_tax_households].first[:covered_individuals].length).to eq 2
      expect(result[:aptc_csr_tax_households].first[:covered_individuals][0][:coverage_start_on]).to eq enrollment_1.start_on
      expect(result[:aptc_csr_tax_households].first[:covered_individuals][0][:coverage_end_on]).to eq enrollment_2.end_on
      expect(result[:aptc_csr_tax_households].first[:covered_individuals][1][:coverage_start_on]).to eq enrollment_2.start_on
      expect(result[:aptc_csr_tax_households].first[:covered_individuals][1][:coverage_end_on]).to eq enrollment_2.end_on
      expect(result[:aptc_csr_tax_households].second[:covered_individuals].length).to eq 1
      expect(result[:aptc_csr_tax_households].second[:covered_individuals][0][:coverage_start_on]).to eq enrollment_1.start_on
      expect(result[:aptc_csr_tax_households].second[:covered_individuals][0][:coverage_end_on]).to eq enrollment_1.end_on
    end
  end

  context "member added during mid month coverage" do
    let(:enrollment_1_subscriber) { FactoryBot.build(:enrolled_member, person: subscriber_person) }
    let(:enrollment_1_dependents) { FactoryBot.build(:enrolled_member, person: dependent_person) }
    let(:enrollment_2_subscriber) { FactoryBot.build(:enrolled_member, person: subscriber_person) }
    let(:enrollment_2_dependent_1) { FactoryBot.build(:enrolled_member, person: dependent_person) }
    let(:enrollment_2_dependent_2) { FactoryBot.build(:enrolled_member, person: another_dependent_person) }
    let!(:enrollment_1) do
      FactoryBot.create(:enrollment, start_on: Date.new(year, 1, 1),
                                     effectuated_on: Date.new(year, 1, 1),
                                     end_on: Date.new(year, 12, 8), insurance_policy: insurance_policy,
                                     subscriber: enrollment_1_subscriber,
                                     dependents: [enrollment_1_dependents])
    end
    let!(:enrollment_2) do
      FactoryBot.create(:enrollment, start_on: Date.new(year, 12, 9),
                                     effectuated_on: Date.new(year, 12, 9),
                                     end_on: Date.new(year, 12, 31), insurance_policy: insurance_policy,
                                     subscriber: enrollment_1_subscriber,
                                     dependents: [enrollment_2_dependent_1, enrollment_2_dependent_2])
    end

    let!(:premium_schedule_1_enrollment_1) { FactoryBot.create(:premium_schedule, enrolled_member: enrollment_1.subscriber) }
    let!(:premium_schedule_2_enrollment_1) do
      FactoryBot.create(:premium_schedule, enrolled_member: enrollment_1.dependents.first)
    end
    let!(:premium_schedule_1_enrollment_2) { FactoryBot.create(:premium_schedule, enrolled_member: enrollment_2.subscriber) }
    let!(:premium_schedule_2_enrollment_2) { FactoryBot.create(:premium_schedule, enrolled_member: enrollment_2.dependents[0]) }
    let!(:premium_schedule_3_enrollment_2) { FactoryBot.create(:premium_schedule, enrolled_member: enrollment_2.dependents[1]) }
    let!(:aqhp_tax_household_1) { FactoryBot.create(:tax_household, is_aqhp: true) }
    let!(:aqhp_tax_household_2) { FactoryBot.create(:tax_household, is_aqhp: true) }

    let!(:aqhp_thh_1_sub_tax_household_member) do
      FactoryBot.create(:tax_household_member, tax_household: aqhp_tax_household_1, person: subscriber_person,
                                               is_tax_filer: true)
    end
    let!(:aqhp_thh_1_dep_1_tax_household_member) do
      FactoryBot.create(:tax_household_member, tax_household: aqhp_tax_household_1, person: dependent_person,
                                               is_tax_filer: false)
    end

    let!(:aqhp_thh_2_sub_tax_household_member) do
      FactoryBot.create(:tax_household_member, tax_household: aqhp_tax_household_2, person: subscriber_person,
                                               is_tax_filer: true)
    end
    let!(:aqhp_thh_2_dep_1_tax_household_member) do
      FactoryBot.create(:tax_household_member, tax_household: aqhp_tax_household_2, person: dependent_person,
                                               is_tax_filer: false)
    end

    let!(:aqhp_thh_1_dep_2_tax_household_member) do
      FactoryBot.create(:tax_household_member, tax_household: aqhp_tax_household_2, person: another_dependent_person,
                                               is_tax_filer: false)
    end
    let!(:aqhp_enrollment_tax_household_1) do
      FactoryBot.create(:enrollments_tax_households, enrollment_id: enrollment_1.id, tax_household_id: aqhp_tax_household_1.id)
    end

    let!(:aqhp_enrollment_tax_household_2) do
      FactoryBot.create(:enrollments_tax_households, enrollment_id: enrollment_2.id, tax_household_id: aqhp_tax_household_2.id)
    end

    it "should return 1 tax_households with correct member coverage dates" do
      result = subject.call({ insurance_policy: insurance_policy })
      expect(result.success?).to be_truthy
      result = result.value!
      expect(result[:aptc_csr_tax_households].length).to eq 1
      expect(result[:aptc_csr_tax_households].first[:covered_individuals].length).to eq 3
      expect(result[:aptc_csr_tax_households].first[:covered_individuals][0][:coverage_start_on]).to eq enrollment_1.start_on
      expect(result[:aptc_csr_tax_households].first[:covered_individuals][0][:coverage_end_on]).to eq enrollment_2.end_on
      expect(result[:aptc_csr_tax_households].first[:covered_individuals][1][:coverage_start_on]).to eq enrollment_1.start_on
      expect(result[:aptc_csr_tax_households].first[:covered_individuals][1][:coverage_end_on]).to eq enrollment_2.end_on
      expect(result[:aptc_csr_tax_households].first[:covered_individuals][2][:coverage_start_on]).to eq enrollment_2.start_on
      expect(result[:aptc_csr_tax_households].first[:covered_individuals][2][:coverage_end_on]).to eq enrollment_2.end_on
    end
  end
end
