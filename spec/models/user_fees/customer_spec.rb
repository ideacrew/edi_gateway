# frozen_string_literal: true

require 'rails_helper'
require 'shared_examples/user_fees/customer_params'

RSpec.describe UserFees::Customer, type: :model, db_clean: :before do
  include_context 'customer_params'
  subject { described_class }

  context 'Given valid Customer parameters, but no associated models' do
    let(:hbx_id) { '1138345' }
    let(:first_name) { 'George' }
    let(:last_name) { 'Jetson' }
    let(:customer_role) { 'subscriber' }
    let(:is_active) { true }
    let(:local_attrs) do
      {
        hbx_id: hbx_id,
        first_name: first_name,
        last_name: last_name,
        customer_role: customer_role,
        is_active: is_active
      }
    end

    it 'the model should be invalid' do
      expect(subject.new(local_attrs).valid?).to be_falsey
    end

    context 'and valid params for an associated Account are added' do
      let(:number) { '1100001'.to_i }
      let(:name) { 'Accounts Receivable' }
      let(:account_kind) { 'asset' }
      let(:account) { ::Keepr::Account.new(number: number, name: name, kind: account_kind) }

      it 'the Account is associated but the Customer model remains invalid' do
        expect(subject.new(local_attrs.merge(account: account)).valid?).to be_falsey
        expect(subject.new(local_attrs.merge(account: account)).account.number).to eq number
      end

      context 'and given invalid InsuranceCoverage parameters' do
        context 'and given a non-Hash, non-InsuranceCoverage instance argument' do
          let(:invalid_coverage_argument_type) { 'invalid_argument' }
          it 'it should raise an ArgumentError' do
            expect { subject.new(insurance_coverage: invalid_coverage_argument_type) }.to raise_error ArgumentError
          end
        end

        context 'and InsuranceModel is invalid' do
          let(:invalid_coverage_instance) { ::UserFees::InsuranceCoverage.new }

          it 'should fail validation' do
            customer = subject.new(local_attrs.merge(account: account, insurance_coverage: invalid_coverage_instance))
            expect(customer.valid?).to be_falsey
          end
        end
      end

      context 'and given valid InsuranceCoverage parameters' do
        let(:validated_insurance_coverage_hash) do
          AcaEntities::Ledger::Contracts::InsuranceCoverageContract.new.call(insurance_coverage).to_h
        end
        let(:insurance_coverage_instance) { ::UserFees::InsuranceCoverage.new(validated_insurance_coverage_hash) }

        it 'InsuranceCoverage values should pass contract validation' do
          expect(
            AcaEntities::Ledger::Contracts::InsuranceCoverageContract.new.call(insurance_coverage).success?
          ).to be_truthy
        end

        context 'in Hash form via constructor' do
          it 'should associate the InsuranceCoverage and be valid' do
            customer =
              subject.new(local_attrs.merge(account: account, insurance_coverage: validated_insurance_coverage_hash))

            expect(customer.insurance_coverage).to be_an_instance_of ::UserFees::InsuranceCoverage
            expect(customer.insurance_coverage_id).to eq customer.insurance_coverage.id.to_s
            expect(customer.valid?).to be_truthy
          end
        end

        context 'in Hash form via setter' do
          it 'should associate the InsuranceCoverage and be valid' do
            customer = subject.new(local_attrs.merge(account: account))
            expect(customer.insurance_coverage).to be_nil

            customer.insurance_coverage = validated_insurance_coverage_hash
            expect(customer.insurance_coverage).to be_an_instance_of ::UserFees::InsuranceCoverage
            expect(customer.insurance_coverage_id).to eq customer.insurance_coverage.id.to_s
            expect(customer.valid?).to be_truthy
          end
        end

        context 'in Class form via contructor' do
          it 'should associate the InsuranceCoverage and be valid' do
            customer = subject.new(local_attrs.merge(account: account, insurance_coverage: insurance_coverage_instance))

            expect(customer.insurance_coverage).to be_an_instance_of ::UserFees::InsuranceCoverage
            expect(customer.insurance_coverage_id).to eq customer.insurance_coverage.id.to_s
            expect(customer.valid?).to be_truthy
          end
        end

        context 'in Class form via setter' do
          it 'should associate the InsuranceCoverage and be valid' do
            customer = subject.new(local_attrs.merge(account: account))
            expect(customer.insurance_coverage).to be_nil

            customer.insurance_coverage = insurance_coverage_instance
            expect(customer.insurance_coverage).to be_an_instance_of ::UserFees::InsuranceCoverage
            expect(customer.insurance_coverage_id).to eq customer.insurance_coverage.id.to_s
            expect(customer.valid?).to be_truthy
          end
        end

        context 'and the Customer is saved' do
          let(:valid_customer) do
            subject.new(local_attrs.merge(account: account, insurance_coverage: validated_insurance_coverage_hash))
          end

          it 'should persist the Customer along with associated Account and InsuranceCoverage' do
            expect(valid_customer.save).to be_truthy
            customer_record = subject.find(valid_customer.id)
            expect(customer_record.account).to eq valid_customer.account
            expect(customer_record.insurance_coverage).to eq valid_customer.insurance_coverage
          end
        end
      end

      context '#to_hash' do
        context 'given a new instance' do
          let(:account) { ::Keepr::Account.new(number: number, name: name, kind: account_kind) }

          let(:validated_insurance_coverage_hash) do
            AcaEntities::Ledger::Contracts::InsuranceCoverageContract.new.call(insurance_coverage).to_h
          end
          let(:account_hash) do
            {
              id: nil,
              number: 1_100_001,
              ancestry: nil,
              name: 'Accounts Receivable',
              kind: 'asset',
              keepr_group_id: nil,
              accountable_type: nil,
              accountable_id: nil,
              keepr_tax_id: nil,
              created_at: nil,
              updated_at: nil
            }
          end

          it 'should return customer and child model attributes in hash structure' do
            result =
              subject.new(local_attrs.merge(account: account, insurance_coverage: validated_insurance_coverage_hash))
            expect(result.to_hash[:hbx_id]).to eq validated_insurance_coverage_hash[:hbx_id]
            expect(result.to_hash.dig(:insurance_coverage, :hbx_id)).to eq validated_insurance_coverage_hash[:hbx_id]
            expect(result.to_hash[:account]).to eq account_hash
          end
        end
      end
    end
  end
end
