# frozen_string_literal: true

require 'shared_examples/edi_database/transactions/initial_transaction'

RSpec.describe EdiDatabase::Transactions::CreateGdbTransaction do
  subject { described_class.new }
  include_context 'initial_transaction'

  context 'and a transaction for a new Customer ' do
    let(:initial_enrollment_transaction) { jetson_initial_transaction }
    let(:hbx_id) { initial_enrollment_transaction.dig(:customer, :hbx_id) }
    let(:uuid_regex) { /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/ }

    it 'should generate an edi_database.transactions.gdb_transaction_created event' do
      result = subject.call(initial_enrollment_transaction)

      expect(result.success?).to be_truthy
      expect(result.success).to be_an_instance_of Events::EdiDatabase::Transactions::GdbTransactionCreated

      # expect(result.success.payload.dig(:meta, :correlation_id)).to match uuid_regex
      expect(result.success.payload.dig(:customer, :hbx_id)).to eq hbx_id
    end
  end
end
