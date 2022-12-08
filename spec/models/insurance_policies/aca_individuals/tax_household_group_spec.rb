# frozen_string_literal: true

require './spec/shared_examples/insurance_policies/shared_insurance_policies'

RSpec.describe InsurancePolicies::AcaIndividuals::TaxHouseholdGroup, type: :model, db_clean: :before do
  include_context 'shared_insurance_policies'

  context "Given valid params to initialize a #{described_class} instance" do
    let(:hbx_id) { '12124' }
    let(:assistance_year) { 2022 }
    let(:application_hbx_id) { '36369' }
    let(:household_group_benchmark_ehb_premium) { BigDecimal('210.98') }
    let(:tax_households) { [shared_insurance_policies_tax_household_one, shared_insurance_policies_tax_household_two] }

    let(:valid_params) do
      {
        hbx_id: hbx_id,
        assistance_year: assistance_year,
        application_hbx_id: application_hbx_id,
        household_group_benchmark_ehb_premium: household_group_benchmark_ehb_premium,
        start_on: Date.today,
        end_on: nil,
        tax_households: tax_households
      }
    end

    it 'the new instance should be valid' do
      result = described_class.new(valid_params)
      expect(result.valid?).to be_truthy
    end

    context 'and it should save and retreive from database' do
      it 'should persist' do
        result = described_class.new(valid_params)
        expect(result.save).to be_truthy
        expect(described_class.all.size).to eq 1

        persisted_instance = described_class.find(result.id)
        expect(persisted_instance).to be_present
      end
    end
  end
end
