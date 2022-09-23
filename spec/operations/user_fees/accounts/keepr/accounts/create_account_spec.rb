# frozen_string_literal: true

RSpec.describe UserFees::Accounts::Keepr::CreateAccount, db_clean: :before do
  subject { described_class.new }

  context 'Given empty Account params' do
    it 'should fail contract validation ' do
      result = subject.call({})
      expect(result.failure?).to be_truthy
    end
  end

  context 'Given a valid Account params' do
    let(:number) { 1_100_001 }
    let(:name) { 'Accounts Receivable' }
    let(:kind) { 'asset' }
    let(:is_active) { true }
    let(:account_params) { { number: number, name: name, kind: kind } }

    context "and the corresponding Account doesn't exist" do
      it 'should create a new Accunt' do
        result = subject.call(account_params)
        expect(result.success?).to be_truthy
        expect(::Keepr::Account.all.size).to eq 1
        expect(::Keepr::Account.find_by(number: number)[:number]).to eq number
      end

      context 'and create is attempted for the same existing Account' do
        let(:account_exists_error) { 'account already exists: 1100001 (Accounts Receivable)' }

        before { subject.call(account_params) }

        it 'should fail to create' do
          expect(::Keepr::Account.all.size).to eq 1
          result = subject.call(account_params)
          expect(result.failure?).to be_truthy
          expect(result.failure).to eq account_exists_error
        end
      end
    end
  end
end
