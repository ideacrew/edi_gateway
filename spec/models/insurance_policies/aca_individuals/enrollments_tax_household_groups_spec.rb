# frozen_string_literal: true

require './spec/shared_examples/insurance_policies/shared_insurance_policies'

RSpec.describe InsurancePolicies::AcaIndividuals::EnrollmentsTaxHouseholdGroups, type: :model, db_clean: :before do
  include_context 'shared_insurance_policies'

  context "Given valid params to initialize a #{described_class} instance" do
    let(:enrollment) { shared_insurance_policies_enrollment }
    let(:tax_household_group) { shared_insurance_policies_tax_household_group }
    let(:tax_household) { tax_household_group[0] }

    let(:valid_params) do
      {
        household_health_benchmark_ehb_premium: household_health_benchmark_ehb_premium,
        household_dental_benchmark_ehb_premium: household_dental_benchmark_ehb_premium,
        household_benchmark_ehb_premium: household_benchmark_ehb_premium,
        applied_aptc: applied_aptc,
        available_max_aptc: available_max_aptc,
        enrollment: enrollment,
        tax_household_group: tax_household_group
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
