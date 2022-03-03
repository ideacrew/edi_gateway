# frozen_string_literal: true

require 'rails_helper'
require 'shared_examples/user_fees/gdb_transactions/initial_transaction'
require 'shared_examples/user_fees/gdb_transactions/add_policy'
# require 'shared_examples/user_fees/gdb_transactions/add_tax_household'
require 'shared_examples/user_fees/gdb_transactions/add_enrolled_member'

RSpec.describe UserFees::GdbTransactions::CheckAdditionTransaction do
  subject { described_class }
  include_context 'initial_transaction'

  context 'Given a new Customer transaction' do
    let(:customer) { jetson_initial_transaction }

    it 'should generate an initial_enrollment_added event'

    context 'and a new policy is added' do
      let(:customer_dental_policy) { jetson_add_dental_policy }

      it 'should generate an enrollment_policy_added event'

      context 'and a new enrolled member is added' do
        let(:customer_add_dependent) { jetson_add_dependent }

        it 'should generate an enrollment_dependent_added event'
      end
    end
  end
end
