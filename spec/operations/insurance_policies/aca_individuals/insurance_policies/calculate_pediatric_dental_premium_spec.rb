# frozen_string_literal: true

RSpec.describe InsurancePolicies::AcaIndividuals::InsurancePolicies::CalculatePediatricDentalPremium, type: :model,
                                                                                                      db_clean: :before do
  subject { described_class.new.call(input_params) }

  describe 'with invalid params' do
    let(:input_params) { {} }

    it 'should return failure' do
      expect(subject).to be_failure
    end

    it 'should return error message' do
      expect(subject.failure).to eq("Please pass in dental_eligible_members")
    end

    context 'when health_eligible_members is blank' do
      let(:input_params) { { dental_eligible_members: "test" } }

      it 'should return failure' do
        expect(subject).to be_failure
        expect(subject.failure).to eq("Please pass in health_eligible_members")
      end
    end

    context 'when dental_policy is blank' do
      let(:input_params) do
        { dental_eligible_members: "test",
          health_eligible_members: "test" }
      end

      it 'should return failure' do
        expect(subject).to be_failure
        expect(subject.failure).to eq("Please pass in is dental policy")
      end
    end

    context 'when calendar_month is blank' do
      let(:input_params) do
        { dental_eligible_members: "test",
          health_eligible_members: "test",
          dental_policy: "test" }
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
        { dental_eligible_members: [double],
          health_eligible_members: [double],
          dental_policy: insurance_policy,
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
            { dental_eligible_members: [subscriber, dependent1, dependent2],
              health_eligible_members: [subscriber, dependent1, dependent2],
              dental_policy: dental_policy,
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
            { dental_eligible_members: [subscriber, dependent1, dependent2],
              health_eligible_members: [subscriber, dependent1, dependent2],
              dental_policy: dental_policy,
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
            { dental_eligible_members: [subscriber, dependent1, dependent2],
              health_eligible_members: [subscriber, dependent1, dependent2],
              dental_policy: dental_policy,
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
            { dental_eligible_members: [subscriber, dependent1, dependent2],
              health_eligible_members: [subscriber, dependent1, dependent2],
              dental_policy: dental_policy,
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
            { dental_eligible_members: [subscriber, dependent1, dependent2],
              health_eligible_members: [subscriber, dependent1, dependent2],
              dental_policy: dental_policy,
              insurance_policy: dental_policy,
              calendar_month: enrollment.end_on.month }
          end

          it 'should return success' do
            expect(subject.success?).to eq true
          end

          it 'should calculate total premium of both health and dental covered days' do
            expect(subject.success).to eq 750.0
          end
        end
      end

      context "both health and dental are covered whole month" do
        let(:health_product) do
          FactoryBot.create(:insurance_product, coverage_type: 'health')
        end

        let(:health_subscriber) do
          FactoryBot.build(:enrolled_member,
                           person: subscriber.person,
                           dob: start_of_year - 30.years)
        end

        let(:health_dependent1) do
          FactoryBot.build(:enrolled_member,
                           person: dependent1.person,
                           dob: start_of_year)
        end

        let(:health_dependent2) do
          FactoryBot.build(:enrolled_member,
                           person: dependent2.person,
                           dob: start_of_year)
        end

        let(:health_policy) do
          FactoryBot.create(:insurance_policy, start_on: Date.new(year, 1, 1),
                                               end_on: Date.new(year, 6, 30),
                                               insurance_product: health_product)
        end

        let!(:health_enrollment) do
          FactoryBot.create(:enrollment, start_on: start_of_year,
                                         effectuated_on: start_of_year,
                                         end_on: Date.new(year, 6, 30),
                                         insurance_policy: health_policy,
                                         subscriber: health_subscriber,
                                         dependents: [health_dependent1, health_dependent2])
        end

        let(:dental_product) do
          FactoryBot.create(:insurance_product, coverage_type: 'dental',
                                                rating_method: 'Age-Based Rates')
        end

        let(:dental_policy) do
          FactoryBot.create(:insurance_policy, start_on: Date.new(year, 1, 1),
                                               end_on: Date.new(year, 6, 30),
                                               insurance_product: dental_product)
        end

        let!(:enrollment) do
          FactoryBot.create(:enrollment, start_on: start_of_year,
                                         effectuated_on: start_of_year,
                                         end_on: Date.new(year, 6, 30),
                                         insurance_policy: dental_policy,
                                         subscriber: subscriber,
                                         dependents: [dependent1, dependent2])
        end

        let!(:premium_schedule_1) { FactoryBot.create(:premium_schedule, enrolled_member: subscriber) }
        let!(:premium_schedule_2) { FactoryBot.create(:premium_schedule, enrolled_member: dependent1) }
        let!(:premium_schedule_3) { FactoryBot.create(:premium_schedule, enrolled_member: dependent2) }

        let(:input_params) do
          { dental_eligible_members: [subscriber, dependent1, dependent2],
            health_eligible_members: [health_subscriber, health_dependent1, health_dependent2],
            dental_policy: dental_policy,
            insurance_policy: dental_policy,
            calendar_month: enrollment.start_on.month }
        end

        it 'should return success' do
          expect(subject.success?).to eq true
        end

        it 'should return total premium' do
          expect(subject.success).to eq 1500.0
        end
      end

      context "health covered for 15 days and dental covered through out the month" do
        let(:health_product) do
          FactoryBot.create(:insurance_product, coverage_type: 'health')
        end

        let(:health_subscriber) do
          FactoryBot.build(:enrolled_member,
                           person: subscriber.person,
                           dob: start_of_year - 30.years)
        end

        let(:health_dependent1) do
          FactoryBot.build(:enrolled_member,
                           person: dependent1.person,
                           dob: start_of_year)
        end

        let(:health_dependent2) do
          FactoryBot.build(:enrolled_member,
                           person: dependent2.person,
                           dob: start_of_year)
        end

        let(:health_policy) do
          FactoryBot.create(:insurance_policy, start_on: Date.new(year, 1, 1),
                                               end_on: Date.new(year, 6, 15),
                                               insurance_product: health_product)
        end

        let!(:health_enrollment) do
          FactoryBot.create(:enrollment, start_on: start_of_year,
                                         effectuated_on: start_of_year,
                                         end_on: Date.new(year, 6, 15),
                                         insurance_policy: health_policy,
                                         subscriber: health_subscriber,
                                         dependents: [health_dependent1, health_dependent2])
        end

        let(:dental_product) do
          FactoryBot.create(:insurance_product, coverage_type: 'dental',
                                                rating_method: 'Age-Based Rates')
        end

        let(:dental_policy) do
          FactoryBot.create(:insurance_policy, start_on: Date.new(year, 1, 1),
                                               end_on: Date.new(year, 6, 30),
                                               insurance_product: dental_product)
        end

        let!(:enrollment) do
          FactoryBot.create(:enrollment, start_on: start_of_year,
                                         effectuated_on: start_of_year,
                                         end_on: Date.new(year, 6, 30),
                                         insurance_policy: dental_policy,
                                         subscriber: subscriber,
                                         dependents: [dependent1, dependent2])
        end

        let!(:premium_schedule_1) { FactoryBot.create(:premium_schedule, enrolled_member: subscriber) }
        let!(:premium_schedule_2) { FactoryBot.create(:premium_schedule, enrolled_member: dependent1) }
        let!(:premium_schedule_3) { FactoryBot.create(:premium_schedule, enrolled_member: dependent2) }

        let(:input_params) do
          { dental_eligible_members: [subscriber, dependent1, dependent2],
            health_eligible_members: [health_subscriber, health_dependent1, health_dependent2],
            dental_policy: dental_policy,
            insurance_policy: dental_policy,
            calendar_month: enrollment.end_on.month }
        end

        it 'should return success' do
          expect(subject.success?).to eq true
        end

        it 'should return 15 day total premium' do
          expect(subject.success).to eq 750.0
        end
      end

      context "health covered through out the month and dental covered for 15 days in a month" do
        let(:health_product) do
          FactoryBot.create(:insurance_product, coverage_type: 'health')
        end

        let(:health_subscriber) do
          FactoryBot.build(:enrolled_member,
                           person: subscriber.person,
                           dob: start_of_year - 30.years)
        end

        let(:health_dependent1) do
          FactoryBot.build(:enrolled_member,
                           person: dependent1.person,
                           dob: start_of_year)
        end

        let(:health_dependent2) do
          FactoryBot.build(:enrolled_member,
                           person: dependent2.person,
                           dob: start_of_year)
        end

        let(:health_policy) do
          FactoryBot.create(:insurance_policy, start_on: Date.new(year, 1, 1),
                                               end_on: Date.new(year, 6, 30),
                                               insurance_product: health_product)
        end

        let!(:health_enrollment) do
          FactoryBot.create(:enrollment, start_on: start_of_year,
                                         effectuated_on: start_of_year,
                                         end_on: Date.new(year, 6, 30),
                                         insurance_policy: health_policy,
                                         subscriber: subscriber,
                                         dependents: [dependent1, dependent2])
        end

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
          { dental_eligible_members: [subscriber, dependent1, dependent2],
            health_eligible_members: [health_enrollment.subscriber,
                                      health_enrollment.dependents.first,
                                      health_enrollment.dependents.last],
            dental_policy: dental_policy,
            insurance_policy: dental_policy,
            calendar_month: enrollment.end_on.month }
        end

        it 'should return success' do
          expect(subject.success?).to eq true
        end

        it 'should return 15 day total premium' do
          expect(subject.success).to eq 750.0
        end
      end

      context "multiple health enrollments covered through out a month and dental covered only for 15 days" do
        let(:health_product) do
          FactoryBot.create(:insurance_product, coverage_type: 'health')
        end

        let(:health_subscriber) do
          FactoryBot.build(:enrolled_member,
                           person: subscriber.person,
                           dob: start_of_year - 30.years)
        end

        let(:health_dependent1) do
          FactoryBot.build(:enrolled_member,
                           person: dependent1.person,
                           dob: start_of_year)
        end

        let(:health_dependent2) do
          FactoryBot.build(:enrolled_member,
                           person: dependent2.person,
                           dob: start_of_year)
        end

        let(:health_policy) do
          FactoryBot.create(:insurance_policy, start_on: Date.new(year, 1, 1),
                                               end_on: Date.new(year, 12, 31),
                                               insurance_product: health_product)
        end

        let!(:health_enrollment) do
          FactoryBot.create(:enrollment, start_on: start_of_year,
                                         effectuated_on: start_of_year,
                                         end_on: Date.new(year, 6, 9),
                                         insurance_policy: health_policy,
                                         subscriber: subscriber,
                                         dependents: [dependent1, dependent2])
        end

        let!(:health_enrollment_2) do
          FactoryBot.create(:enrollment, start_on: start_of_year,
                                         effectuated_on: Date.new(year, 6, 10),
                                         insurance_policy: health_policy,
                                         subscriber: subscriber,
                                         dependents: [dependent1, dependent2])
        end

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
          { dental_eligible_members: [subscriber, dependent1, dependent2],
            health_eligible_members: [health_enrollment.subscriber,
                                      health_enrollment.dependents.first,
                                      health_enrollment.dependents.last],
            dental_policy: dental_policy,
            insurance_policy: dental_policy,
            calendar_month: enrollment.end_on.month }
        end

        it 'should return success' do
          expect(subject.success?).to eq true
        end

        it 'should return 15 day total premium' do
          expect(subject.success).to eq 750.0
        end
      end
    end
  end
end
