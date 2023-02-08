# frozen_string_literal: true

RSpec.describe InsurancePolicies::AcaIndividuals::InsurancePolicy, type: :model, db_clean: :before do
  let(:subscriber_person) { FactoryBot.create(:people_person) }
  let(:dependent_person) { FactoryBot.create(:people_person) }

  let(:year) { Date.new.year }
  let(:insurance_policy) { FactoryBot.create(:insurance_policy, start_on: Date.new(year, 1, 1), end_on: Date.new(year, 12, 31)) }
  let(:subscriber) { FactoryBot.build(:enrolled_member, person: subscriber_person) }
  let(:dependents) { FactoryBot.build(:enrolled_member, person: dependent_person) }
  let!(:enrollment_1) do
    FactoryBot.create(:enrollment, start_on: Date.new(year, 1, 1),
                                   end_on: Date.new(year, 5, 31), insurance_policy: insurance_policy,
                                   subscriber: subscriber,
                                   dependents: [dependents])
  end

  let!(:enrollment_2) do
    FactoryBot.create(:enrollment, start_on: Date.new(year, 6, 1),
                                   end_on: Date.new(year, 12, 31), insurance_policy: insurance_policy,
                                   subscriber: subscriber)
  end

  let!(:enrollment_3) do
    FactoryBot.create(:enrollment, start_on: Date.new(year, 6, 1),
                                   aasm_state: "coverage_canceled",
                                   end_on: Date.new(year, 12, 31), insurance_policy: insurance_policy,
                                   subscriber: subscriber,
                                   dependents: [dependents])
  end

  context "fetch_enrolled_member_end_date" do
    it "should return policy end_on if subscriber present through the coverage period" do
      member_end_date = insurance_policy.fetch_enrolled_member_end_date(subscriber)
      expect(member_end_date).to eq insurance_policy.end_on
    end

    it "should return end_date based on member coverage period" do
      member_end_date = insurance_policy.fetch_enrolled_member_end_date(dependents)
      expect(member_end_date).to eq enrollment_1.end_on
    end
  end

  context "effectuated_enrollments" do
    it "should return enrollments which are only effectuated" do
      enrollments = insurance_policy.effectuated_enrollments
      expect(enrollments).to match_array [enrollment_1, enrollment_2]
      expect(enrollments).not_to include enrollment_3
    end
  end

  context "effectuated_aptc_tax_households_with_unique_composition" do
    context "UQHP case" do
      let(:person) { FactoryBot.create(:person) }
      let(:tax_household) { FactoryBot.create(:tax_household, is_aqhp: false) }
      let(:tax_household_member) do
        FactoryBot.create(:tax_household_member, tax_household: tax_household, person: subscriber_person,
                                                 is_tax_filer: true)
      end
      let!(:enrollment_tax_household) do
        FactoryBot.create(:enrollments_tax_households, enrollment_id: enrollment_1.id, tax_household_id: tax_household.id)
      end

      it "should return valid tax_households" do
        result = insurance_policy.effectuated_aptc_tax_households_with_unique_composition
        expect(result).to include(tax_household)
      end
    end

    context "AQHP cases" do
      let(:tax_household_1) { FactoryBot.create(:tax_household, is_aqhp: true) }
      let(:tax_household_2) { FactoryBot.create(:tax_household, is_aqhp: true) }
      let(:tax_household_3) { FactoryBot.create(:tax_household, is_aqhp: true) }
      let!(:tax_household_member_1) do
        FactoryBot.create(:tax_household_member, tax_household: tax_household_1, person: subscriber_person,
                                                 is_tax_filer: true)
      end
      let!(:tax_household_member_2) do
        FactoryBot.create(:tax_household_member, tax_household: tax_household_2, person: dependent_person,
                                                 is_tax_filer: true)
      end
      let!(:tax_household_member_3) do
        FactoryBot.create(:tax_household_member, tax_household: tax_household_3, person: subscriber_person,
                                                 is_tax_filer: true)
      end
      let!(:enrollment_tax_household_1) do
        FactoryBot.create(:enrollments_tax_households, enrollment_id: enrollment_1.id, tax_household_id: tax_household_1.id)
      end
      let!(:enrollment_tax_household_2) do
        FactoryBot.create(:enrollments_tax_households, enrollment_id: enrollment_1.id, tax_household_id: tax_household_2.id)
      end
      let!(:enrollment_tax_household_3) do
        FactoryBot.create(:enrollments_tax_households, enrollment_id: enrollment_1.id, tax_household_id: tax_household_3.id)
      end

      it "should return valid tax_households" do
        result = insurance_policy.effectuated_aptc_tax_households_with_unique_composition
        expect(result).to match_array([tax_household_1, tax_household_2])
      end
    end
  end
end
