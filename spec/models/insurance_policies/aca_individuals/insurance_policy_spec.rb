# frozen_string_literal: true

RSpec.describe InsurancePolicies::AcaIndividuals::InsurancePolicy, type: :model, db_clean: :before do
  let(:subscriber_person) { FactoryBot.create(:person) }
  let(:dependent_person) { FactoryBot.create(:person) }

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
end
