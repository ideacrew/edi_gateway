# frozen_string_literal: true

require 'spec_helper'
require 'shared_examples/cv3_family'
require 'shared_examples/assisted_policy/one_enrolled_member'

RSpec.describe Tax1095a::PublishFamilyPayload do
  include_context 'one_enrolled_member'

  before :all do
    DatabaseCleaner.clean
  end

  subject { described_class.new }

  describe '#call' do
    context ".success" do
      let(:valid_params) do
        {
          tax_year: 2023,
          tax_form_type: 'IVL_CAP',
          irs_group_id: "2200000001000533",
          transmission_kind: '1095a',
          reporting_year: 2023,
          report_type: 'notice',
          policy_hbx_ids: [1, 2, 3]
        }
      end

      context 'when all steps succeed' do
        before do
          enrollment_1.insurance_policy.insurance_product.update_attributes(metal_level: "catastrophic")
          enrollment_2.insurance_policy.insurance_product.update_attributes(metal_level: "catastrophic")
          @result = subject.call(valid_params)
        end

        it 'returns success' do
          expect(@result).to be_success
        end

        it 'return published payload with insurance_agreements' do
          insurance_agreements = @result.success.dig(1, :households, 0, :insurance_agreements)
          expect(insurance_agreements.present?).to be_truthy
        end
      end
    end

    context ".failure with invalid params" do
      before do
        @result = subject.call(invalid_params)
      end

      context 'when irs_group_id is invalid' do
        let(:invalid_params) do
          {
            tax_year: 2023,
            tax_form_type: 'IVL_CAP',
            irs_group_id: "123",
            transmission_kind: '1095a',
            reporting_year: 2023,
            report_type: 'notice',
            policy_hbx_ids: [1, 2, 3]
          }
        end

        it 'returns a failure result' do
          expect(@result).to be_failure
        end

        it 'returns a failure result with error message' do
          expect(@result.failure).to eq("Unable to fetch IRS group for irs_group_id: #{invalid_params[:irs_group_id]}")
        end
      end

      context "tax_year is invalid" do
        let(:invalid_params) do
          {
            tax_year: nil,
            tax_form_type: 'IVL_CAP',
            irs_group_id: "2200000001000533",
            transmission_kind: '1095a',
            reporting_year: 2023,
            report_type: 'notice',
            policy_hbx_ids: [1, 2, 3]
          }
        end

        it 'returns a failure result' do
          expect(@result).to be_failure
        end

        it 'returns a failure result with error message' do
          expect(@result.failure).to eq(["tax_year required"])
        end
      end

      context "tax_form_type is invalid" do
        let(:invalid_params) do
          {
            tax_year: 2023,
            tax_form_type: nil,
            irs_group_id: "2200000001000533",
            transmission_kind: '1095a',
            reporting_year: 2023,
            report_type: 'notice',
            policy_hbx_ids: [1, 2, 3]
          }
        end

        it 'returns a failure result' do
          expect(@result).to be_failure
        end

        it 'returns a failure result with error message' do
          expect(@result.failure).to eq(["tax_form_type required"])
        end
      end

      context "irs_group_id is invalid" do
        let(:invalid_params) do
          {
            tax_year: 2023,
            tax_form_type: 'IVL_CAP',
            irs_group_id: nil,
            transmission_kind: '1095a',
            reporting_year: 2023,
            report_type: 'notice',
            policy_hbx_ids: [1, 2, 3]
          }
        end

        it 'returns a failure result' do
          expect(@result).to be_failure
        end

        it 'returns a failure result with error message' do
          expect(@result.failure).to eq(["irs_group_id required"])
        end
      end

      context "transmission_kind is invalid" do
        let(:invalid_params) do
          {
            tax_year: 2023,
            tax_form_type: 'IVL_CAP',
            irs_group_id: "2200000001000533",
            transmission_kind: nil,
            reporting_year: 2023,
            report_type: 'notice',
            policy_hbx_ids: [1, 2, 3]
          }
        end

        it 'returns a failure result' do
          expect(@result).to be_failure
        end

        it 'returns a failure result with error message' do
          expect(@result.failure).to eq(["transmission_kind should be one of 1095a"])
        end
      end
    end

    context ".failure when no product" do
      context "when policies are not catastrophic" do
        let(:valid_params) do
          {
            tax_year: 2023,
            tax_form_type: 'IVL_CAP',
            irs_group_id: "2200000001000533",
            transmission_kind: '1095a',
            reporting_year: 2023,
            report_type: 'notice',
            policy_hbx_ids: [1, 2, 3]
          }
        end

        before do
          @result = subject.call(valid_params)
        end

        it 'returns a failure result' do
          expect(@result).to be_failure
        end

        it 'returns error message' do
          expect(@result.failure).to eq("Unable to fetch insurance policies for irs_group_id: #{valid_params[:irs_group_id]}")
        end
      end
    end
  end
end
