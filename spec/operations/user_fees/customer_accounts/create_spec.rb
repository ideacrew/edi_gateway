# frozen_string_literal: true

require 'rails_helper'
require 'shared_examples/user_fees/customer_account_params'

RSpec.describe UserFees::CustomerAccounts::Create do
  subject { described_class.new }
  include_context 'customer_account_params'

  context 'Given an empty CustomerAccount transaction' do
    context
    it 'should fail contract validation ' do
      result = subject.call({})
      expect(result.failure?).to be_truthy
    end
  end

  context 'Given a valid CustomerAccount transaction' do
    context "and the corresponding CustomerAccount doesn't exist" do
      let(:new_account_params) { { customer_account: transaction } }
      let(:customer_id) { new_account_params[:customer_account][:customer][:hbx_id] }
      let(:customer_role) { new_account_params[:customer_account][:customer_role] }

      it 'should create a new CustomerAccount' do
        result = subject.call(new_account_params)
        expect(result.success?).to be_truthy
        expect(UserFees::CustomerAccount.all.size).to eq 1
      end

      it 'should be accessible by querying the database' do
        result = UserFees::CustomerAccount.by_customer_id(value: customer_id).first
        expect(result.customer_role).to eq customer_role
      end

      context 'and create is attempted for the same existing CustomerAccount' do
        let(:failure_message) { 'customer_id already exists: 1055668' }

        it 'should fail to create' do
          expect(UserFees::CustomerAccount.by_customer_id(value: customer_id).count).to be > 0
          result = subject.call(new_account_params)
          expect(result.failure?).to be_truthy
          expect(result.failure).to eq failure_message
        end
      end
    end
  end
end
