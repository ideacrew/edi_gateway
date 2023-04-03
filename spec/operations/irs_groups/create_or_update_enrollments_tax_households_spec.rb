# frozen_string_literal: true

require 'shared_examples/cv3_family'

RSpec.describe IrsGroups::CreateOrUpdateEnrollmentsTaxHouseholds do
  subject { described_class.new }
  include_context 'cv3_family'

  it "should fail if payload is invalid" do
    res = subject.call({ family: {}, enrollment: {} })
    expect(res.failure).to be_truthy
  end

  it "should fail if passed in family is not a family entity" do
    res = subject.call({ family: {}, enrollment: {} })
    expect(res.failure).to be_truthy
    expect(res.failure).to eq "Please pass in family entity"
  end

  it "should fail if enrollment are blank" do
    res = subject.call({ family: family_entity, enrollment: {} })
    expect(res.failure).to be_truthy
    expect(res.failure).to eq "Enrollment should not be blank"
  end

  it "should return success and create new enrollment tax household" do
    insurance_policy = create(:insurance_policy)
    _enrollment = create(:enrollment, insurance_policy: insurance_policy, hbx_id: "1000")
    _tax_household = create(:tax_household, hbx_id: "828762")
    expect(InsurancePolicies::AcaIndividuals::EnrollmentsTaxHouseholds.all.count).to eq 0
    res = subject.call({ family: family_entity, enrollment: family_entity.households.first.hbx_enrollments.first })
    expect(res.success?).to be_truthy
    expect(InsurancePolicies::AcaIndividuals::EnrollmentsTaxHouseholds.all.count).to eq 1
  end

  it "should return success and should not create new enrollment tax household" do
    insurance_policy = create(:insurance_policy)
    enrollment = create(:enrollment, insurance_policy: insurance_policy, hbx_id: "1000")
    tax_household = create(:tax_household, hbx_id: "828762")
    _enrollment_tax_household = create(:enrollments_tax_households, enrollment: enrollment, tax_household: tax_household)
    expect(InsurancePolicies::AcaIndividuals::EnrollmentsTaxHouseholds.all.count).to eq 1
    expect(InsurancePolicies::AcaIndividuals::EnrollmentsTaxHouseholds.all.first.applied_aptc.to_f).to eq 200.0
    expect(InsurancePolicies::AcaIndividuals::EnrollmentsTaxHouseholds.all.first.household_benchmark_ehb_premium.to_f).to eq 400.0
    res = subject.call({ family: family_entity, enrollment: family_entity.households.first.hbx_enrollments.first })
    expect(res.success?).to be_truthy
    expect(InsurancePolicies::AcaIndividuals::EnrollmentsTaxHouseholds.all.count).to eq 1
    expect(InsurancePolicies::AcaIndividuals::EnrollmentsTaxHouseholds.all.first.applied_aptc.to_f).to eq 0.0
    expect(InsurancePolicies::AcaIndividuals::EnrollmentsTaxHouseholds.all.first.household_benchmark_ehb_premium.to_f).to eq 0.0
  end
end
