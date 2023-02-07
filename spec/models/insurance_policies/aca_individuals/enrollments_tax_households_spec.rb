# frozen_string_literal: true

require './spec/shared_examples/insurance_policies/shared_insurance_policies'

RSpec.describe InsurancePolicies::AcaIndividuals::EnrollmentsTaxHouseholds, type: :model, db_clean: :before do
  include_context 'shared_insurance_policies'

  context "Given valid params to initialize a #{described_class} instance" do
    let(:household_health_benchmark_ehb_premium) { BigDecimal('450.0') }
    let(:household_dental_benchmark_ehb_premium) { BigDecimal('120.0') }
    let(:household_benchmark_ehb_premium) { BigDecimal('350.0') }
    let(:applied_aptc) { BigDecimal('175.0') }
    let(:available_max_aptc) { BigDecimal('850.0') }

    let(:tax_household_group) { shared_insurance_policies_tax_household_group }
    let(:tax_household) { tax_household_group[0] }

    let(:valid_params) do
      {
        applied_aptc: applied_aptc,
        available_max_aptc: available_max_aptc,
        tax_household: shared_insurance_policies_tax_household_one
      }
    end

    before { tax_household_group.save }

    it 'the new instance should be valid' do
      result = described_class.new(valid_params)
      expect(result.valid?).to be_truthy
      # expect(result.to_hash.except(:id, :created_at, :updated_at, :tax_household_id)).to eq valid_params
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
