# frozen_string_literal: true

require 'shared_examples/assisted_policy/one_enrolled_member'

RSpec.describe InsurancePolicies::AcaIndividuals::IrsGroups::ConstructCv3Payload do
  include_context 'one_enrolled_member'

  subject { described_class.new.call(input_args) }

  context 'with valid input params' do
    let(:input_args) { { tax_form_type: 'IVL_TAX', irs_group: irs_group } }
    let(:success_result) { subject.success }

    it 'returns success with a clean family cv' do
      expect(
        AcaEntities::Contracts::Families::FamilyContract.new.call(success_result).success?
      ).to be_truthy
    end

    context 'with catastrophic policy' do
      before do
        product = insurance_policy_1.insurance_product
        product.update_attributes!(metal_level: 'catastrophic')
        product
      end

      it 'returns success with a clean family cv' do
        expect(
          AcaEntities::Contracts::Families::FamilyContract.new.call(success_result).success?
        ).to be_truthy
      end

      it 'returns success with catastrophic policy included' do
        expect(
          success_result[:households].first[:insurance_agreements].first[:insurance_policies].first[:policy_id]
        ).to eq(insurance_policy_1.policy_id)
      end
    end
  end
end
