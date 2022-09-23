# frozen_string_literal: true

require 'shared_examples/user_fees/customer_params'

RSpec.describe UserFees::Customers::Create, db_clean: :before do
  subject { described_class.new }
  include_context 'customer_params'

  context 'Given an empty Customer transaction' do
    context
    it 'should fail contract validation ' do
      result = subject.call({})
      expect(result.failure?).to be_truthy
    end
  end

  context 'Given a valid Customer transaction' do
    context "and the corresponding Customer doesn't exist" do
      let(:new_account_params) { { customer: transaction } }
      let(:hbx_id) { new_account_params[:customer][:hbx_id] }

      it 'should create a new Customer' do
        result = subject.call(new_account_params)
        expect(result.success?).to be_truthy
        expect(UserFees::Customer.all.size).to eq 1
        expect(::UserFees::Customer.find_by(hbx_id: hbx_id).id).to eq result.success.id
      end

      context 'and create is attempted for the same existing Customer' do
        let(:failure_message) { 'customer_id already exists: 1055668' }

        it 'should fail to create' do
          result1 = subject.call(new_account_params)
          expect(result1.success?).to be_truthy
          expect(::UserFees::Customer.find_by(hbx_id: hbx_id).id).to eq result1.success.id
          expect { subject.call(new_account_params) }.to raise_error ActiveRecord::RecordInvalid
        end
      end
    end
  end
end
