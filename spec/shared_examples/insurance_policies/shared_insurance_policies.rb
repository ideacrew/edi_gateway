# frozen_string_literal: true

RSpec.shared_context 'shared_insurance_policies' do
  # Enrollment
  let(:enrollment_total_premium) { BigDecimal('1200.0') }
  let(:enrollment_total_premium_adjustments) { BigDecimal('400.0') }
  let(:enrollment_total_responsible_premium) { BigDecimal('800.0') }
  let(:enrollment_start_on) { Date.new(Date.today.year, 1, 1) }
  let(:enrollment_start_on) { nil }

  let(:shared_insurance_policies_enrollment) do
    InsurancePolicies::AcaIndividuals::Enrollment.new(
      total_premium: enrollment_total_premium,
      total_premium_adjustments: enrollment_total_premium_adjustments,
      total_responsible_premium: enrollment_total_responsible_premium,
      start_on: enrollment_start_on,
      end_on: enrollment_end_on
    )
  end

  let(:tax_household_hbx_id_one) { '101101' }
  let(:tax_household_hbx_id_two) { '101102' }
  let(:tax_household_is_eligibility_determined) { true }

  let(:tax_household_allocated_aptc_one) { BigDecimal('100.0') }
  let(:tax_household_max_aptc_one) { BigDecimal('500.00') }
  let(:tax_household_yearly_expected_contribution_one) { BigDecimal('125.00') }
  let(:tax_household_start_on_one) { Date.today }
  let(:tax_household_end_on_one) { Date.today }

  # TaxHouseholdGroup
  let(:tax_household_group_hbx_id) { '30101' }
  let(:tax_household_group_assistance_year) { Date.today.year }
  let(:tax_household_group_application_hbx_id) { '40101' }
  let(:tax_household_group_household_group_benchmark_ehb_premium) { BigDecimal('600.00') }
  let(:tax_household_group_tax_households) do
    [shared_insurance_policies_tax_household_one, shared_insurance_policies_tax_household_two]
  end
  let(:tax_household_group_start_on) { Date.new(Date.today.year, 1, 1) }
  let(:tax_household_group_end_on) { nil }

  let(:shared_insurance_policies_tax_household_group) do
    InsurancePolicies::AcaIndividuals::TaxHouseholdGroup.new(
      hbx_id: tax_household_group_hbx_id,
      assistance_year: tax_household_group_assistance_year,
      application_hbx_id: tax_household_group_application_hbx_id,
      household_group_benchmark_ehb_premium: tax_household_group_household_group_benchmark_ehb_premium,
      start_on: tax_household_group_start_on,
      end_on: tax_household_group_end_on,
      tax_households: tax_household_group_tax_households
    )
  end

  # TaxHouseholds
  let(:shared_insurance_policies_tax_household_one) do
    InsurancePolicies::AcaIndividuals::TaxHousehold.new(
      hbx_id: tax_household_hbx_id_one,
      is_eligibility_determined: tax_household_is_eligibility_determined,
      max_aptc: tax_household_max_aptc_one,
      allocated_aptc: tax_household_allocated_aptc_one,
      yearly_expected_contribution: tax_household_yearly_expected_contribution_one,
      start_on: tax_household_start_on_one,
      end_on: nil,
      tax_household_members: [
        shared_insurance_policies_tax_household_member_tax_filer_a,
        shared_insurance_policies_tax_household_non_tax_filer_member_c
      ]
    )
  end

  let(:tax_household_allocated_aptc_two) { BigDecimal('200.00') }
  let(:tax_household_max_aptc_two) { BigDecimal('1000.00') }
  let(:tax_household_yearly_expected_contribution_two) { BigDecimal('250.00') }
  let(:tax_household_start_on_two) { Date.new(Date.today.year, 1, 1) }
  let(:tax_household_end_on_two) { Date.today }

  let(:shared_insurance_policies_tax_household_two) do
    InsurancePolicies::AcaIndividuals::TaxHousehold.new(
      hbx_id: tax_household_hbx_id_two,
      is_eligibility_determined: tax_household_is_eligibility_determined,
      max_aptc: tax_household_max_aptc_two,
      allocated_aptc: tax_household_allocated_aptc_two,
      yearly_expected_contribution: tax_household_yearly_expected_contribution_two,
      start_on: tax_household_start_on_two,
      end_on: nil,
      tax_household_members: [
        shared_insurance_policies_tax_household_member_tax_filer_b,
        shared_insurance_policies_tax_household_non_tax_filer_member_d
      ]
    )
  end

  # TaxHouseholdMembers
  let(:tax_household_member_person_hbx_id_a) { '1001' }
  let(:tax_household_member_person_hbx_id_b) { '1002' }
  let(:tax_household_member_person_hbx_id_c) { '1003' }
  let(:tax_household_member_person_hbx_id_d) { '1004' }
  let(:tax_household_member_is_subscriber_true) { true }
  let(:tax_household_member_is_tax_filer_true) { true }
  let(:tax_household_member_is_subscriber_false) { false }
  let(:tax_household_member_is_tax_filer_false) { false }
  let(:tax_household_member_reason) { '' }

  let(:shared_insurance_policies_tax_household_member_tax_filer_a) do
    InsurancePolicies::AcaIndividuals::TaxHouseholdMember.new(
      person_hbx_id: tax_household_member_person_hbx_id_a,
      is_subscriber: tax_household_member_is_subscriber_true,
      is_tax_filer: tax_household_member_is_tax_filer_true,
      reason: tax_household_member_reason
    )
  end

  let(:shared_insurance_policies_tax_household_member_tax_filer_b) do
    InsurancePolicies::AcaIndividuals::TaxHouseholdMember.new(
      person_hbx_id: tax_household_member_person_hbx_id_b,
      is_subscriber: tax_household_member_is_subscriber_true,
      is_tax_filer: tax_household_member_is_tax_filer_true,
      reason: tax_household_member_reason
    )
  end

  let(:shared_insurance_policies_tax_household_non_tax_filer_member_c) do
    InsurancePolicies::AcaIndividuals::TaxHouseholdMember.new(
      person_hbx_id: tax_household_member_person_hbx_id_c,
      is_subscriber: tax_household_member_is_subscriber_false,
      is_tax_filer: tax_household_member_is_tax_filer_false,
      reason: tax_household_member_reason
    )
  end

  let(:shared_insurance_policies_tax_household_non_tax_filer_member_d) do
    InsurancePolicies::AcaIndividuals::TaxHouseholdMember.new(
      person_hbx_id: tax_household_member_person_hbx_id_d,
      is_subscriber: tax_household_member_is_subscriber_false,
      is_tax_filer: tax_household_member_is_tax_filer_false,
      reason: tax_household_member_reason
    )
  end
end
