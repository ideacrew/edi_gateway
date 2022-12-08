# frozen_string_literal: true

RSpec.shared_context 'shared_insurance_policies' do
  let(:tax_household_hbx_id) { '828762' }
  let(:tax_household_is_eligibility_determined) { true }

  let(:tax_household_allocated_aptc) { BigDecimal('0.0') }
  let(:tax_household_max_aptc) { BigDecimal('510.98') }
  let(:tax_household_yearly_expected_contribution) { BigDecimal('102.78238') }
  let(:tax_household_start_on) { Date.today }
  let(:tax_household_end_on) { Date.today }

  # TaxHousehold
  let(:shared_insurance_policies_tax_household) do
    InsurancePolicies::AcaIndividuals::TaxHousehold.new(
      hbx_id: tax_household_hbx_id,
      is_eligibility_determined: tax_household_is_eligibility_determined,
      allocated_aptc: tax_household_allocated_aptc,
      max_aptc: tax_household_max_aptc,
      yearly_expected_contribution: tax_household_yearly_expected_contribution,
      start_on: tax_household_start_on,
      end_on: nil,
      tax_household_members: [shared_insurance_policies_tax_household_member]
    )
  end

  # TaxHouseholdMember
  let(:tax_household_member_person_hbx_id) { '1001' }
  let(:tax_household_member_is_subscriber) { true }
  let(:tax_household_member_is_tax_filer) { true }
  let(:tax_household_member_reason) { '' }

  let(:shared_insurance_policies_tax_household_member) do
    InsurancePolicies::AcaIndividuals::TaxHouseholdMember.new(
      person_hbx_id: tax_household_member_person_hbx_id,
      is_subscriber: tax_household_member_is_subscriber,
      is_tax_filer: tax_household_member_is_tax_filer,
      reason: tax_household_member_reason
    )
  end
end
