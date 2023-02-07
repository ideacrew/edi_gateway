# frozen_string_literal: true

require './spec/shared_examples/people/shared_people'
require './spec/shared_examples/insurance_policies/shared_insurance_policies'
require './spec/shared_examples/locations/addresses/shared_addresses'
require './spec/shared_examples/contacts/shared_contacts'
require './spec/models/domain_models/domainable_spec'

RSpec.describe InsurancePolicies::AcaIndividuals::TaxHouseholdMember, type: :model, db_clean: :before do
  include_context 'shared_insurance_policies'
  include_context 'shared_people'
  include_context 'shared_contacts'
  include_context 'shared_addresses'

  context 'Model supports Domain Model behaviors' do
    it_behaves_like 'domainable'
  end

  context "Given valid params to initialize a #{described_class} instance" do
    let(:hbx_id) { '1001' }
    let(:is_subscriber) { true }
    let(:is_tax_filer) { true }

    let(:financial_assistance_applicant) { true }
    let(:is_ia_eligible) { false }
    let(:is_medicaid_chip_eligible) { false }
    let(:is_totally_ineligible) { false }
    let(:is_uqhp_eligible) { false }
    let(:is_non_magi_medicaid_eligible) { false }
    let(:is_without_assistance) { false }
    let(:reason) { '' }

    let(:relation_with_primary) { 'self' }
    let(:tax_filer_status) { 'tax_filer' }

    let(:tax_household_group) { shared_insurance_policies_tax_household_group }
    let(:tax_household) { tax_household_group.tax_households.first }
    let(:person) { shared_people_person_primary }

    let(:valid_params) do
      {
        person: person,
        tax_household: tax_household,
        hbx_id: hbx_id,
        is_subscriber: is_subscriber,
        is_tax_filer: is_tax_filer,
        reason: reason,
        financial_assistance_applicant: financial_assistance_applicant,
        is_ia_eligible: is_ia_eligible,
        is_medicaid_chip_eligible: is_medicaid_chip_eligible,
        is_totally_ineligible: is_totally_ineligible,
        is_uqhp_eligible: is_uqhp_eligible,
        is_without_assistance: is_without_assistance,
        is_non_magi_medicaid_eligible: is_non_magi_medicaid_eligible,
        tax_filer_status: tax_filer_status,
        relation_with_primary: relation_with_primary
      }
    end

    let(:model_params) { valid_params.except(:person, :tax_household) }

    it 'the new instance should be valid' do
      result = described_class.new(valid_params)
      expect(
        result.to_hash.except(:id, :created_at, :updated_at, :person, :person_id, :tax_household_id, :tax_household)
      ).to eq model_params
    end
  end
end
