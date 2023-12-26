# frozen_string_literal: true

RSpec.describe InsurancePolicies::AcaIndividuals::InsurancePolicies::CalculateTotalPremium do
  subject { described_class.new.call(input_params) }

  describe 'with invalid params' do
    let(:input_params) { {} }

    it 'should return failure' do
      expect(subject).to be_failure
    end

    it 'should return error message' do
      expect(subject.failure).to eq("Please pass in enrolled_members")
    end

    context 'when insurance_policy is blank' do
      let(:input_params) { { enrolled_members: "test" } }

      it 'should return failure' do
        expect(subject).to be_failure
        expect(subject.failure).to eq("Please pass in is insurance policy")
      end
    end

    context 'when insurance_policy is blank' do
      let(:input_params) do
        { enrolled_members: "test",
          insurance_policy: "test" }
      end

      it 'should return failure' do
        expect(subject).to be_failure
        expect(subject.failure).to eq("Please pass in is calendar_month")
      end
    end
  end

  describe 'with valid params' do
    let(:year) { Date.today.year }
    let(:start_of_year) { Date.new(year) }
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

    context 'when insurance_product is health' do
      let(:insurance_policy) do
        FactoryBot.create(:insurance_policy, start_on: Date.new(year, 1, 1),
                                             end_on: Date.new(year, 12, 31))
      end

      let(:input_params) do
        { enrolled_members: [double],
          insurance_policy: insurance_policy,
          calendar_month: 1 }
      end

      it 'should return success' do
        expect(subject.success?).to eq true
        expect(subject.success).to eq 0.0
      end
    end

    context 'dental policy' do
      context "Family Tier Rating" do
        context 'when rating method is family tier and policy is effectuated through the year' do
          let(:primary_enrollee_two_dependent) { 150.00 }

          let(:dental_product) do
            FactoryBot.create(:insurance_product, coverage_type: 'dental',
                                                  rating_method: 'Family-Tier Rates',
                                                  primary_enrollee_two_dependent: primary_enrollee_two_dependent)
          end

          let(:dental_policy) do
            FactoryBot.create(:insurance_policy, start_on: Date.new(year, 1, 1),
                                                 end_on: Date.new(year, 12, 31),
                                                 insurance_product: dental_product)
          end

          let!(:enrollment) do
            FactoryBot.create(:enrollment, start_on: start_of_year,
                                           effectuated_on: start_of_year,
                                           end_on: Date.new(year, 12, 31),
                                           insurance_policy: dental_policy,
                                           subscriber: subscriber,
                                           dependents: [dependent1, dependent2])
          end

          let(:input_params) do
            { enrolled_members: [subscriber, dependent1, dependent2],
              insurance_policy: dental_policy,
              calendar_month: enrollment.start_on.month }
          end

          it 'should return success' do
            expect(subject.success?).to eq true
          end

          it 'should return total premium' do
            expect(subject.success).to eq 150.0
          end
        end

        context 'when rating method is family tier and policy is terminated mid year mid month' do
          let(:primary_enrollee_two_dependent) { 150.00 }

          let(:dental_product) do
            FactoryBot.create(:insurance_product, coverage_type: 'dental',
                                                  rating_method: 'Family-Tier Rates',
                                                  primary_enrollee_two_dependent: primary_enrollee_two_dependent)
          end

          let(:dental_policy) do
            FactoryBot.create(:insurance_policy, start_on: Date.new(year, 1, 1),
                                                 end_on: Date.new(year, 6, 15),
                                                 insurance_product: dental_product)
          end

          let!(:enrollment) do
            FactoryBot.create(:enrollment, start_on: start_of_year,
                                           effectuated_on: start_of_year,
                                           end_on: Date.new(year, 6, 15),
                                           insurance_policy: dental_policy,
                                           subscriber: subscriber,
                                           dependents: [dependent1, dependent2])
          end

          let(:input_params) do
            { enrolled_members: [subscriber, dependent1, dependent2],
              insurance_policy: dental_policy,
              calendar_month: enrollment.end_on.month }
          end

          it 'should return success' do
            expect(subject.success?).to eq true
          end

          it 'should return total premium' do
            expect(subject.success).to eq 75.0
          end
        end

        context 'when rating method is family tier and policy is terminated and a dependent is dropped mid year' do
          let(:primary_enrollee_two_dependent) { 150.00 }

          let(:dental_product) do
            FactoryBot.create(:insurance_product, coverage_type: 'dental',
                                                  rating_method: 'Family-Tier Rates',
                                                  primary_enrollee_two_dependent: primary_enrollee_two_dependent)
          end

          let(:dental_policy) do
            FactoryBot.create(:insurance_policy, start_on: Date.new(year, 1, 1),
                                                 end_on: Date.new(year, 6, 15),
                                                 insurance_product: dental_product)
          end

          let!(:enrollment) do
            FactoryBot.create(:enrollment, start_on: start_of_year,
                                           effectuated_on: start_of_year,
                                           end_on: Date.new(year, 6, 15),
                                           insurance_policy: dental_policy,
                                           subscriber: subscriber,
                                           dependents: [dependent1, dependent2])
          end

          let!(:enrollment_2) do
            FactoryBot.create(:enrollment, start_on: start_of_year,
                                           effectuated_on: Date.new(year, 6, 16),
                                           end_on: Date.new(year, 6, 30),
                                           insurance_policy: dental_policy,
                                           subscriber: subscriber,
                                           dependents: [dependent1])
          end

          let(:input_params) do
            { enrolled_members: [subscriber, dependent1, dependent2],
              insurance_policy: dental_policy,
              calendar_month: enrollment.end_on.month }
          end

          it 'should return success' do
            expect(subject.success?).to eq true
          end

          it 'should return total premium' do
            expect(subject.success).to eq 125.0
          end
        end
      end

      context "Age based Rating" do
        context 'when rating method is family tier and policy is effectuated through the year' do
          let(:dental_product) do
            FactoryBot.create(:insurance_product, coverage_type: 'dental',
                                                  rating_method: 'Age-Based Rates')
          end

          let(:dental_policy) do
            FactoryBot.create(:insurance_policy, start_on: Date.new(year, 1, 1),
                                                 end_on: Date.new(year, 12, 31),
                                                 insurance_product: dental_product)
          end

          let!(:enrollment) do
            FactoryBot.create(:enrollment, start_on: start_of_year,
                                           effectuated_on: start_of_year,
                                           end_on: Date.new(year, 12, 31),
                                           insurance_policy: dental_policy,
                                           subscriber: subscriber,
                                           dependents: [dependent1, dependent2])
          end

          let!(:premium_schedule_1) { FactoryBot.create(:premium_schedule, enrolled_member: subscriber) }
          let!(:premium_schedule_2) { FactoryBot.create(:premium_schedule, enrolled_member: dependent1) }
          let!(:premium_schedule_3) { FactoryBot.create(:premium_schedule, enrolled_member: dependent2) }

          let(:input_params) do
            { enrolled_members: [subscriber, dependent1, dependent2],
              insurance_policy: dental_policy,
              calendar_month: enrollment.end_on.month }
          end

          it 'should return success' do
            expect(subject.success?).to eq true
          end

          it 'should return total premium' do
            expect(subject.success).to eq 1500.0
          end
        end

        context 'when rating method is family tier and policy is terminated mid year mid month' do
          let(:dental_product) do
            FactoryBot.create(:insurance_product, coverage_type: 'dental',
                                                  rating_method: 'Age-Based Rates')
          end

          let(:dental_policy) do
            FactoryBot.create(:insurance_policy, start_on: Date.new(year, 1, 1),
                                                 end_on: Date.new(year, 6, 15),
                                                 insurance_product: dental_product)
          end

          let!(:enrollment) do
            FactoryBot.create(:enrollment, start_on: start_of_year,
                                           effectuated_on: start_of_year,
                                           end_on: Date.new(year, 6, 15),
                                           insurance_policy: dental_policy,
                                           subscriber: subscriber,
                                           dependents: [dependent1, dependent2])
          end

          let!(:premium_schedule_1) { FactoryBot.create(:premium_schedule, enrolled_member: subscriber) }
          let!(:premium_schedule_2) { FactoryBot.create(:premium_schedule, enrolled_member: dependent1) }
          let!(:premium_schedule_3) { FactoryBot.create(:premium_schedule, enrolled_member: dependent2) }

          let(:input_params) do
            { enrolled_members: [subscriber, dependent1, dependent2],
              insurance_policy: dental_policy,
              calendar_month: enrollment.end_on.month }
          end

          it 'should return success' do
            expect(subject.success?).to eq true
          end

          it 'should return total premium' do
            expect(subject.success).to eq 750.0
          end
        end
      end
    end
  end
end
