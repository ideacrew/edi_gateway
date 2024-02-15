# frozen_string_literal: true

require 'shared_examples/assisted_policy/one_enrolled_member'

RSpec.describe ::Tax1095a::Transformers::InsurancePolicies::Cv3Family do
  include_context 'one_enrolled_member'
  subject { described_class.new }

  describe 'with valid params, construct payload' do
    before :each do
      @valid_result = subject.call({ tax_year: insurance_agreement_1.plan_year, tax_form_type: "IVL_TAX",
                                     irs_group_id: irs_group.irs_group_id })
    end

    it 'should return success' do
      expect(@valid_result.success?).to be_truthy
    end

    it 'should return payload' do
      example_output_hash = JSON.parse(File.read(Pathname.pwd.join("spec/test_payloads/sample_cv3_family_policies.json")))
      contract = AcaEntities::Contracts::Families::FamilyContract.new.call(example_output_hash)
      entity_cv3_payload = AcaEntities::Families::Family.new(contract.to_h)
      result = JSON.parse(entity_cv3_payload.to_hash.to_json)
      generated_payload = JSON.parse(@valid_result.value!.to_json)
      expect(generated_payload["households"][0]["insurance_agreements"].present?).to be_truthy
      expect(generated_payload["households"][0]["insurance_agreements"].count).to eq 2
    end
  end

  describe 'with invalid params, do not construct payload' do
    before :each do
      @invalid_result = subject.call({ tax_year: insurance_agreement_1.plan_year, tax_form_type: "",
                                       irs_group_id: irs_group.irs_group_id })
    end

    it 'should return failure' do
      expect(@invalid_result.failure?).to be_truthy
    end
  end
end
