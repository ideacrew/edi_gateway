# frozen_string_literal: true

require './spec/shared_examples/insurance_policies/shared_insurance_policies'
require './spec/models/domain_models/domainable_spec'

RSpec.describe InsurancePolicies::AcaIndividuals::TaxHousehold, type: :model, db_clean: :before do
  include_context 'shared_insurance_policies'

  before do
    DatabaseCleaner.clean
  end

  context 'Domain Model behavior' do
    it_behaves_like 'domainable'
  end

  context "Given valid params to initialize a #{described_class} instance" do
    let(:hbx_id) { '828762' }
    let(:is_eligibility_determined) { true }

    let(:allocated_aptc) { BigDecimal('0.0') }
    let(:max_aptc) { BigDecimal('510.98') }
    let(:yearly_expected_contribution) { BigDecimal('102.78238') }

    let(:tax_household_members) do
      [
        shared_insurance_policies_tax_household_member_tax_filer_a,
        shared_insurance_policies_tax_household_non_tax_filer_member_c
      ]
    end

    let(:tax_household_group) { shared_insurance_policies_tax_household_group }
    let(:tax_household) { tax_household_group.tax_households.first }

    let(:valid_params) do
      {
        hbx_id: hbx_id,
        is_eligibility_determined: is_eligibility_determined,
        allocated_aptc: allocated_aptc,
        max_aptc: max_aptc,
        yearly_expected_contribution: yearly_expected_contribution,
        start_on: Date.today,
        end_on: nil,
        tax_household_members: tax_household_members,
        tax_household_group: tax_household_group
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

  context "AQHP" do
    context "Only 1 tax filer" do
      it "should return the tax_filer" do
        person = create(:people_person)
        tax_household = create(:tax_household)
        thh_member_1 = create(:tax_household_member, tax_filer_status: "tax_filer", tax_household: tax_household,
                                                     person: person)
        expect(tax_household.primary).to eq thh_member_1
      end
    end

    context "multiple tax filers with married filing jointly" do
      it "should return the tax_filer" do
        person_1 = create(:people_person)
        person_2 = create(:people_person)
        tax_household = create(:tax_household)
        thh_member_1 = create(:tax_household_member, tax_filer_status: "tax_filer",
                                                     tax_household: tax_household, relation_with_primary: "self",
                                                     person: person_1)
        _thh_member_2 = create(:tax_household_member, tax_filer_status: "tax_filer", tax_household: tax_household,
                                                      relation_with_primary: "spouse",
                                                      person: person_2)

        expect(tax_household.primary).to eq thh_member_1
      end
    end

    context "no tax filers and no primary person in a tax_household" do
      it "should return the tax_filer" do
        person = create(:people_person)
        tax_household = create(:tax_household)
        thh_member = create(:tax_household_member, tax_filer_status: "non_filer",
                                                   tax_household: tax_household, relation_with_primary: "child",
                                                   person: person)

        expect(tax_household.primary).to eq thh_member
      end
    end

    context "multiple tax filers with spouse and child as tax_filers" do
      it "should return the tax_filer" do
        person_1 = create(:people_person, hbx_id: "12345")
        person_2 = create(:people_person, hbx_id: "45678")
        tax_household = create(:tax_household)
        _thh_member_1 = create(:tax_household_member, tax_filer_status: "tax_filer",
                                                      tax_household: tax_household, relation_with_primary: "spouse",
                                                      person: person_2)
        thh_member_2 = create(:tax_household_member, tax_filer_status: "tax_filer", tax_household: tax_household,
                                                     relation_with_primary: "child",
                                                     person: person_1)

        expect(tax_household.primary).to eq thh_member_2
      end
    end
  end

  context "UQHP" do
    context "No tax_filers but has people with relation as self" do
      it "should return relation with self" do
        person = create(:people_person, hbx_id: "12345")
        tax_household = create(:tax_household)
        thh_member_1 = create(:tax_household_member, tax_filer_status: nil,
                                                     tax_household: tax_household, relation_with_primary: "self",
                                                     person: person)
        expect(tax_household.primary).to eq thh_member_1
      end
    end

    context "No tax_filers but no people with relation as self" do
      it "should return relation with self" do
        person = create(:people_person, hbx_id: "12345")
        tax_household = create(:tax_household)
        thh_member_1 = create(:tax_household_member, tax_filer_status: nil,
                                                     tax_household: tax_household, relation_with_primary: "spouse",
                                                     person: person)
        expect(tax_household.primary).to eq thh_member_1
      end
    end
  end
end
