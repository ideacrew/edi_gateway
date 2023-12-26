# frozen_string_literal: true

RSpec.describe InsurancePolicies::AcaIndividuals::Enrollment, type: :model, db_clean: :before do
  before :all do
    DatabaseCleaner.clean
  end

  let(:subscriber_person) { FactoryBot.create(:people_person) }
  let(:dependent_person) { FactoryBot.create(:people_person) }
  let(:dependent_person2) { FactoryBot.create(:people_person) }
  let(:year) { Date.today.year }
  let(:insurance_policy) do
    FactoryBot.create(:insurance_policy, start_on: Date.new(year, 1, 1), end_on: Date.new(year, 12, 31))
  end
  let(:subscriber) { FactoryBot.build(:enrolled_member, person: subscriber_person) }
  let(:dependents) do
    [
      FactoryBot.build(:enrolled_member, person: dependent_person),
      FactoryBot.build(:enrolled_member, person: dependent_person2)
    ]
  end

  let(:enrollment) do
    FactoryBot.create(:enrollment, start_on: Date.new(year, 1, 1),
                                   effectuated_on: Date.new(year, 1, 1),
                                   end_on: Date.new(year, 5, 31),
                                   insurance_policy: insurance_policy,
                                   subscriber: subscriber,
                                   dependents: dependents)
  end

  let(:tax_household_members) do
    [
      double('InsurancePolicies::AcaIndividuals::TaxHouseholdMember', is_medicaid_chip_eligible: true, person: subscriber_person),
      double('InsurancePolicies::AcaIndividuals::TaxHouseholdMember', is_medicaid_chip_eligible: true, person: dependent_person),
      double('InsurancePolicies::AcaIndividuals::TaxHouseholdMember', is_medicaid_chip_eligible: true, person: dependent_person2)
    ]
  end

  let(:premium) { 90.25 }
  let(:calendar_month) { (1..11).to_a.sample }

  before do
    allow(::IrsGroups::CalculateDentalPremiumForEnrolledChildren).to receive(:new).and_return(
      double('IrsGroups::CalculateDentalPremiumForEnrolledChildren', call: double(value!: BigDecimal(premium.to_s)))
    )
  end

  describe '#pediatric_dental_premium' do
    context 'all members eligible for medicaid_chip_eligible' do
      it 'returns pediatric dental premium' do
        expect(
          enrollment.pediatric_dental_premium([enrollment], tax_household_members, calendar_month)
        ).to eq(premium)
      end
    end
  end

  describe '#fetch_eligible_enrollees' do
    it 'returns eligible members' do
      expect(
        enrollment.fetch_eligible_enrollees([enrollment], tax_household_members)
      ).to match_array([subscriber, dependents.first, dependents.second])
    end
  end
end
