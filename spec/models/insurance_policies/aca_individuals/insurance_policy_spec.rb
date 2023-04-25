# frozen_string_literal: true

RSpec.describe InsurancePolicies::AcaIndividuals::InsurancePolicy, type: :model, db_clean: :before do
  let(:subscriber_person) { FactoryBot.create(:people_person) }
  let(:dependent_person) { FactoryBot.create(:people_person) }
  let(:another_dependent_person) { FactoryBot.create(:people_person) }

  let(:year) { Date.today.year }
  let(:insurance_policy) { FactoryBot.create(:insurance_policy, start_on: Date.new(year, 1, 1), end_on: Date.new(year, 12, 31)) }
  let(:subscriber) { FactoryBot.build(:enrolled_member, person: subscriber_person) }
  let(:dependents) { FactoryBot.build(:enrolled_member, person: dependent_person) }
  let!(:enrollment_1) do
    FactoryBot.create(:enrollment, start_on: Date.new(year, 1, 1),
                                   effectuated_on: Date.new(year, 1, 1),
                                   end_on: Date.new(year, 5, 31), insurance_policy: insurance_policy,
                                   subscriber: subscriber)
  end

  let!(:enrollment_2) do
    FactoryBot.create(:enrollment, start_on: Date.new(year, 6, 1),
                                   effectuated_on: Date.new(year, 6, 1),
                                   end_on: Date.new(year, 12, 31), insurance_policy: insurance_policy,
                                   subscriber: subscriber,
                                   dependents: [dependents])
  end

  let!(:enrollment_3) do
    FactoryBot.create(:enrollment, start_on: Date.new(year, 6, 1),
                                   effectuated_on: Date.new(year, 6, 1),
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
      expect(member_end_date).to eq enrollment_2.end_on
    end
  end

  context "#fetch_member_start_on" do
    it "should return policy start_on if subscriber present through the coverage period" do
      member_end_date = insurance_policy.fetch_member_start_on(subscriber_person.hbx_id)
      expect(member_end_date).to eq insurance_policy.start_on
    end

    it "should return start_on on enrollment if member has been added mid coverage" do
      member_end_date = insurance_policy.fetch_member_start_on(dependent_person.hbx_id)
      expect(member_end_date).to eq enrollment_2.start_on
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

    context "AQHP cases with assistance_eligible and medicaid eligible people in different tax_households" do
      let(:tax_household_1) { FactoryBot.create(:tax_household, is_aqhp: true) }
      let(:tax_household_2) { FactoryBot.create(:tax_household, is_aqhp: true) }
      let(:tax_household_3) { FactoryBot.create(:tax_household, is_aqhp: true) }
      let!(:tax_household_member_1) do
        FactoryBot.create(:tax_household_member, tax_household: tax_household_1, person: subscriber_person,
                                                 is_tax_filer: true)
      end
      let!(:tax_household_member_2) do
        FactoryBot.create(:tax_household_member, tax_household: tax_household_2, person: dependent_person,
                                                 tax_filer_status: "non_filer",
                                                 is_tax_filer: false)
      end
      let!(:tax_household_member_3) do
        FactoryBot.create(:tax_household_member, tax_household: tax_household_3, person: another_dependent_person,
                                                 tax_filer_status: "non_filer",
                                                 is_tax_filer: false)
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

      it "should return valid tax_households with uniq members as filers" do
        result = insurance_policy.effectuated_aptc_tax_households_with_unique_composition
        expect(result).to match_array([tax_household_1, tax_household_2, tax_household_3])
      end
    end

    context "UQHP and AQHP cases" do
      let(:person) { FactoryBot.create(:person) }
      let(:tax_household_1) { FactoryBot.create(:tax_household, is_aqhp: false) }
      let(:tax_household_2) { FactoryBot.create(:tax_household, is_aqhp: true) }
      let(:tax_household_member_1) do
        FactoryBot.create(:tax_household_member, tax_household: tax_household, person: subscriber_person,
                                                 is_tax_filer: true)
      end
      let(:tax_household_member_2) do
        FactoryBot.create(:tax_household_member, tax_household: tax_household, person: subscriber_person,
                                                 is_tax_filer: true)
      end
      let!(:enrollment_tax_household_1) do
        FactoryBot.create(:enrollments_tax_households, enrollment_id: enrollment_1.id, tax_household_id: tax_household_1.id)
      end
      let!(:enrollment_tax_household_2) do
        FactoryBot.create(:enrollments_tax_households, enrollment_id: enrollment_1.id, tax_household_id: tax_household_2.id)
      end

      it "should return valid AQHP tax_households" do
        result = insurance_policy.effectuated_aptc_tax_households_with_unique_composition
        expect(result).to include(tax_household_2)
      end
    end
  end

  context "#fetch_tax_filer" do
    let(:tax_household_1) { FactoryBot.create(:tax_household, is_aqhp: false) }
    let(:tax_household_2) { FactoryBot.create(:tax_household, is_aqhp: true) }
    let!(:tax_household_member_1) do
      FactoryBot.create(:tax_household_member, tax_household: tax_household_1, person: subscriber_person,
                                               is_subscriber: true)
    end
    let!(:tax_household_member_2) do
      FactoryBot.create(:tax_household_member, tax_household: tax_household_2, person: dependent_person,
                                               is_subscriber: true, tax_filer_status: "tax_filer")
    end

    it "should return subscriber if tax_household is uqhp" do
      expect(insurance_policy.fetch_tax_filer(tax_household_1)).to eq tax_household_member_1
    end

    it "should return tax_filer if tax_household is aqhp" do
      expect(insurance_policy.fetch_tax_filer(tax_household_2)).to eq tax_household_member_2
    end
  end

  context "#enrollments_for_month" do
    it "should not return canceled enrollments if exists" do
      result = insurance_policy.enrollments_for_month(6, year)
      expect(result).to match_array([enrollment_2])
      expect(result).not_to include([enrollment_3])
    end

    it "should return enrollments which exists in a given month and year" do
      result = insurance_policy.enrollments_for_month(5, year)
      expect(result).to match_array([enrollment_1])
      expect(result).not_to include([enrollment_2])
    end
  end

  context "#applied_aptc_amount_for" do
    let(:enrollment_1_subscriber) { FactoryBot.build(:enrolled_member, person: subscriber_person) }
    let(:enrollment_1_dependents) { FactoryBot.build(:enrolled_member, person: dependent_person) }

    let(:enrollment_2_subscriber) { FactoryBot.build(:enrolled_member, person: subscriber_person) }
    let(:enrollment_2_dependents) { FactoryBot.build(:enrolled_member, person: dependent_person) }
    let!(:enrollment_1) do
      FactoryBot.create(:enrollment, start_on: Date.new(year, 1, 1),
                                     effectuated_on: Date.new(year, 1, 1),
                                     end_on: Date.new(year, 5, 31), insurance_policy: insurance_policy,
                                     subscriber: enrollment_1_subscriber,
                                     dependents: [enrollment_1_dependents])
    end

    let!(:enrollment_2) do
      FactoryBot.create(:enrollment, start_on: Date.new(year, 6, 1),
                                     effectuated_on: Date.new(year, 6, 1),
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
      FactoryBot.create(:enrollments_tax_households, enrollment_id: enrollment_2.id, tax_household_id: aqhp_tax_household_3.id,
                                                     applied_aptc: "0.00")
    end

    it "should return premium amount for the people in the tax_household" do
      calendar_month = 6
      enrollments_for_month = insurance_policy.enrollments_for_month(calendar_month, year)
      result = insurance_policy.applied_aptc_amount_for(enrollments_for_month, calendar_month, aqhp_tax_household_3)
      expect(result).to eq "0.00"
    end
  end

  context "#fetch_slcsp_premium" do
    context "when aptc is zero" do
      let(:enrollment_subscriber) { FactoryBot.build(:enrolled_member, person: subscriber_person) }
      let!(:enrollment) do
        FactoryBot.create(:enrollment, start_on: Date.new(year, 1, 1),
                                       effectuated_on: Date.new(year, 1, 1),
                                       end_on: Date.new(year, 12, 31),
                                       insurance_policy: insurance_policy,
                                       subscriber: enrollment_subscriber)
      end
      let!(:premium_schedule_enrollment) { FactoryBot.create(:premium_schedule, enrolled_member: enrollment.subscriber) }
      let!(:aqhp_tax_household) { FactoryBot.create(:tax_household, is_aqhp: true) }
      let!(:aqhp_thh_sub_tax_household_member) do
        FactoryBot.create(:tax_household_member, tax_household: aqhp_tax_household, person: subscriber_person,
                                                 is_tax_filer: true)
      end
      let!(:aqhp_enrollment_tax_household) do
        FactoryBot.create(:enrollments_tax_households, enrollment_id: enrollment.id,
                                                       tax_household_id: aqhp_tax_household.id, applied_aptc: 0.0)
      end

      it "should return 0 if aptc amount is 0" do
        expect(insurance_policy.fetch_slcsp_premium([enrollment], 1, aqhp_tax_household,
                                                    aqhp_enrollment_tax_household.applied_aptc)).to eq "0.00"
      end
    end

    context "when aptc is non zero" do
      let(:enrollment_subscriber) { FactoryBot.build(:enrolled_member, person: subscriber_person) }
      let!(:enrollment) do
        FactoryBot.create(:enrollment, start_on: Date.new(year, 1, 1),
                                       effectuated_on: Date.new(year, 1, 1),
                                       end_on: Date.new(year, 12, 31),
                                       insurance_policy: insurance_policy,
                                       subscriber: enrollment_subscriber)
      end
      let!(:premium_schedule_enrollment) { FactoryBot.create(:premium_schedule, enrolled_member: enrollment.subscriber) }
      let!(:aqhp_tax_household) { FactoryBot.create(:tax_household, is_aqhp: true) }
      let!(:aqhp_thh_sub_tax_household_member) do
        FactoryBot.create(:tax_household_member, tax_household: aqhp_tax_household, person: subscriber_person,
                                                 is_tax_filer: true)
      end
      let!(:aqhp_enrollment_tax_household) do
        FactoryBot.create(:enrollments_tax_households, enrollment_id: enrollment.id,
                                                       tax_household_id: aqhp_tax_household.id)
      end

      it "should return 0 if aptc amount is 0" do
        expect(insurance_policy.fetch_slcsp_premium([enrollment], 1, aqhp_tax_household,
                                                    aqhp_enrollment_tax_household.applied_aptc)).to eq "400.00"
      end
    end
  end
end
