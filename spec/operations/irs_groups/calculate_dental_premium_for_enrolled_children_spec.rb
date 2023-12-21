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

  let(:input_params) do
    {
      enrollment: enrollment,
      enrolled_people: ([enrollment.subscriber] + enrollment.dependents),
      month: Date.today.month
    }
  end

  context 'with 3 dependents on dental enrollment' do
    let!(:dental_enrollment) do
      FactoryBot.create(:enrollment, start_on: start_of_year,
                                     effectuated_on: start_of_year,
                                     end_on: Date.new(year, 12, 31),
                                     insurance_policy: dental_policy,
                                     subscriber: subscriber,
                                     dependents: dependents)
    end

    let(:dependents) { [dependent1, dependent2, dependent3] }

    it 'returns value for primary_enrollee_two_dependent' do
      expect(subject.success.to_f).to eq(primary_enrollee_two_dependent)
    end
  end

  context 'with more than 3 dependents on dental enrollment' do
    let!(:dental_enrollment) do
      FactoryBot.create(:enrollment, start_on: start_of_year,
                                     effectuated_on: start_of_year,
                                     end_on: Date.new(year, 12, 31),
                                     insurance_policy: dental_policy,
                                     subscriber: subscriber,
                                     dependents: dependents)
    end

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

  context 'with only 1 dependent who was 19 at start of coverage' do
    let!(:dental_enrollment) do
      FactoryBot.create(:enrollment, start_on: start_of_year,
                                     effectuated_on: start_of_year,
                                     end_on: Date.new(year, 12, 31),
                                     insurance_policy: dental_policy,
                                     subscriber: subscriber,
                                     dependents: dependents)
    end

    let(:dependent5) do
      FactoryBot.build(:enrolled_member,
                       person: FactoryBot.create(:people_person),
                       dob: Date.new(year - 19, 1, 1))
    end

    let(:dependents) { [dependent5] }

    it 'return should 0' do
      expect(subject.success.to_f).to eq(0.0)
    end
  end

  context "with 2 insurance policies in same month and year" do
    let(:dental_policy_2) do
      FactoryBot.create(:insurance_policy, start_on: Date.new(year, 1, 1),
                                           end_on: Date.new(year, 10, 10),
                                           irs_group: insurance_policy.irs_group,
                                           insurance_product: dental_product)
    end

    let(:dental_policy_3) do
      FactoryBot.create(:insurance_policy, start_on: Date.new(year, 10, 11),
                                           end_on: Date.new(year, 11, 30),
                                           irs_group: insurance_policy.irs_group,
                                           insurance_product: dental_product)
    end

    let!(:dental_enrollment_2) do
      FactoryBot.create(:enrollment, start_on: start_of_year,
                                     effectuated_on: start_of_year,
                                     end_on: Date.new(year, 10, 10),
                                     insurance_policy: dental_policy_2,
                                     subscriber: subscriber)
    end

    let!(:dental_enrollment_3) do
      FactoryBot.create(:enrollment, start_on: start_of_year,
                                     effectuated_on: start_of_year,
                                     end_on: Date.new(year, 11, 30),
                                     insurance_policy: dental_policy_3,
                                     subscriber: subscriber)
    end

    let(:dependents) { [dependent1, dependent2, dependent3] }

    let(:insurance_policy_2) do
      FactoryBot.create(:insurance_policy, start_on: Date.new(year, 1, 1), end_on: Date.new(year, 10, 10),
                                           irs_group: insurance_policy.irs_group)
    end

    let(:insurance_policy_3) do
      FactoryBot.create(:insurance_policy, start_on: Date.new(year, 10, 11), end_on: Date.new(year, 12, 31),
                                           irs_group: insurance_policy.irs_group)
    end

    let!(:enrollment_1) do
      FactoryBot.create(:enrollment, start_on: start_of_year,
                                     effectuated_on: start_of_year,
                                     end_on: Date.new(year, 10, 10),
                                     insurance_policy: insurance_policy_2,
                                     subscriber: subscriber,
                                     dependents: dependents)
    end

    let!(:enrollment_2) do
      FactoryBot.create(:enrollment, start_on: Date.new(year, 10, 11),
                                     effectuated_on: Date.new(year, 10, 11),
                                     end_on: Date.new(year, 12, 31),
                                     insurance_policy: insurance_policy_3,
                                     subscriber: subscriber,
                                     dependents: dependents)
    end

    let(:input_params) do
      {
        enrollment: enrollment_2,
        enrolled_people: ([enrollment_1.subscriber] + enrollment_1.dependents),
        month: enrollment_2.start_on.month + 1
      }
    end

    let(:operation_instance) { described_class.new }
    let(:result) { operation_instance.call(input_params) }

    context "fetch_dental_policy" do
      it "should return valid policy depending on the enrollment start date" do
        result
        expect(result.success?).to eq true
        expect(operation_instance.dental_policy).to eq dental_policy_3
      end
    end
  end
end
