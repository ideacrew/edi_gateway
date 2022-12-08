# frozen_string_literal: true

RSpec.describe InsurancePolicies::AcaIndividuals::TaxHousehold, type: :model, db_clean: :before do
  context "Given valid params to initialize a #{described_class} instance" do
    let(:hbx_id) { '828762' }
    let(:is_eligibility_determined) { true }

    # let(:allocated_aptc) { { cents: 0.0, currency_iso: 'USD' } }
    let(:allocated_aptc) { BigDecimal('0.0') }
    let(:max_aptc) { BigDecimal('510.98') }
    let(:yearly_expected_contribution) { BigDecimal('102.78238') }

    # Tax Household Member
    let(:person_hbx_id) { '1001' }
    let(:is_subscriber) { true }
    let(:is_tax_filer) { true }
    let(:reason) { '' }

    let(:tax_household_members) do
      [
        InsurancePolicies::AcaIndividuals::TaxHouseholdMember.new(
          person_hbx_id: person_hbx_id,
          is_subscriber: is_subscriber,
          is_tax_filer: is_tax_filer,
          reason: reason
        )
      ]
    end

    let(:valid_params) do
      {
        hbx_id: hbx_id,
        is_eligibility_determined: is_eligibility_determined,
        allocated_aptc: allocated_aptc,
        max_aptc: max_aptc,
        yearly_expected_contribution: yearly_expected_contribution,
        start_on: Date.today,
        end_on: nil,
        tax_household_members: tax_household_members
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
