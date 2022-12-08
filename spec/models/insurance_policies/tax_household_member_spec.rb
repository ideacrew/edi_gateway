# frozen_string_literal: true

RSpec.describe InsurancePolicies::AcaIndividuals::TaxHouseholdMember, type: :model, db_clean: :before do
  context "Given valid params to initialize a #{described_class} instance" do
    let(:person_hbx_id) { '1001' }
    let(:is_subscriber) { true }
    let(:is_tax_filer) { true }

    let(:valid_params) do
      { person_hbx_id: person_hbx_id, is_subscriber: is_subscriber, is_tax_filer: is_tax_filer, reason: '' }
    end

    it 'the new instance should be valid' do
      result = described_class.new(valid_params)
      expect(result.to_hash.except(:id, :created_at, :updated_at, :tax_household_id)).to eq valid_params
    end
  end
end
