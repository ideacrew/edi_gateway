# frozen_string_literal: true

RSpec.describe IrsGroups::CalculateDentalPremiumForEnrolledChildren, type: :model, db_clean: :before do
  subject { described_class.new.call(input_params) }

  let(:year) { Date.today.year }
  let(:start_of_year) { Date.new(year) }

  let(:insurance_policy) { FactoryBot.create(:insurance_policy, start_on: Date.new(year, 1, 1), end_on: Date.new(year, 12, 31)) }
  let(:subscriber) do
    FactoryBot.build(:enrolled_member,
                     person: FactoryBot.create(:people_person),
                     dob: start_of_year - 30.years)
  end

  let(:dependent1) do
    FactoryBot.build(:enrolled_member,
                     person: FactoryBot.create(:people_person),
                     dob: start_of_year)
  end

  let(:dependent2) do
    FactoryBot.build(:enrolled_member,
                     person: FactoryBot.create(:people_person),
                     dob: start_of_year)
  end

  let(:dependent3) do
    FactoryBot.build(:enrolled_member,
                     person: FactoryBot.create(:people_person),
                     dob: start_of_year)
  end

  let!(:enrollment) do
    FactoryBot.create(:enrollment, start_on: start_of_year,
                                   effectuated_on: start_of_year,
                                   end_on: Date.new(year, 12, 31),
                                   insurance_policy: insurance_policy,
                                   subscriber: subscriber,
                                   dependents: dependents)
  end

  let(:primary_enrollee_two_dependent) { 115.00 }

  let(:dental_product) do
    FactoryBot.create(:insurance_product, coverage_type: 'dental',
                                          rating_method: 'Family-Tier Rates',
                                          primary_enrollee_two_dependent: primary_enrollee_two_dependent)
  end

  let(:dental_policy) do
    FactoryBot.create(:insurance_policy, start_on: Date.new(year, 1, 1),
                                         end_on: Date.new(year, 12, 31),
                                         irs_group: insurance_policy.irs_group,
                                         insurance_product: dental_product)
  end

  let!(:dental_enrollment) do
    FactoryBot.create(:enrollment, start_on: start_of_year,
                                   effectuated_on: start_of_year,
                                   end_on: Date.new(year, 12, 31),
                                   insurance_policy: dental_policy,
                                   subscriber: subscriber,
                                   dependents: dependents)
  end

  let(:input_params) do
    {
      enrollment: enrollment,
      enrolled_people: ([enrollment.subscriber] + enrollment.dependents),
      month: Date.today.month
    }
  end

  context 'with 3 dependents on dental enrollment' do
    let(:dependents) { [dependent1, dependent2, dependent3] }

    it 'returns value for primary_enrollee_two_dependent' do
      expect(subject.success.to_f).to eq(primary_enrollee_two_dependent)
    end
  end

  context 'with more than 3 dependents on dental enrollment' do
    let(:dependent4) do
      FactoryBot.build(:enrolled_member,
                       person: FactoryBot.create(:people_person),
                       dob: start_of_year - 3.years)
    end

    let(:dependents) { [dependent1, dependent2, dependent3, dependent4] }

    it 'returns value for primary_enrollee_two_dependent' do
      expect(subject.success.to_f).to eq(primary_enrollee_two_dependent)
    end
  end
end
