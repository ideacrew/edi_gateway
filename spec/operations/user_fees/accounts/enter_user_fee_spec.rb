# frozen_string_literal: true
# # frozen_string_literal: true

# require 'shared_examples/user_fees/customer_params'

# RSpec.describe UserFees::Accounts::EnterUserFee, db_clean: :before do
#   subject { described_class.new }
#   include_context 'customer_params'

#   let(:enrollment_year) { Date.today.year }

#   let!(:customer_parent_account) do
#     Keepr::Account.create!(number: 1000, name: 'Customer Premium Rollup', kind: :asset)
#   end

#   let!(:jetson_customer_account) do
#     Keepr::Account.create!(number: 1_000_001, name: 'Jetson, George', kind: :asset, parent: customer_parent_account)
#   end

#   let!(:insurer_premium_rollup_account) do
#     Keepr::Account.create!(number: 2200, name: 'Insurer Premiums', kind: :revenue)
#   end
#   let!(:hp_insurer_premium_account) do
#     Keepr::Account.create!(
#       number: 2_200_001,
#       name: 'Harvard Pilgrim Premiums',
#       kind: :revenue,
#       parent: insurer_premium_rollup_account
#     )
#   end
#   let!(:anthem_insurer_premium_account) do
#     Keepr::Account.create!(
#       number: 2_200_002,
#       name: 'Anthem Premiums',
#       kind: :revenue,
#       parent: insurer_premium_rollup_account
#     )
#   end

#   let!(:sbm_user_fee_ar_account) do
#     Keepr::Account.create!(number: 3000, name: 'SBM User Fees Accounts Receivable', kind: :revenue)
#   end

#   let!(:insurer_user_fee_rollup_account) do
#     Keepr::Account.create!(number: 5000, name: 'Insurer User Fees', kind: :revenue)
#   end
#   let!(:hp_insurer_user_fee_credit_account) do
#     Keepr::Account.create!(
#       number: 5_000_001,
#       name: 'Harvard Pilgrim User Fees',
#       kind: :revenue,
#       parent: insurer_user_fee_rollup_account
#     )
#   end
#   let!(:hp_insurer_user_fee_debit_account) do
#     Keepr::Account.create!(number: 6_000_002, name: 'Anthem User Fees', kind: :revenue)
#   end

#   let!(:anthem_insurer_user_fee_adjustment_credit_account) do
#     Keepr::Account.create!(number: 7_000_001, name: 'Anthem User Fee Credit Adjustments', kind: :revenue)
#   end
#   let!(:anthem_insurer_user_fee_adjustment_debit_account) do
#     Keepr::Account.create!(number: 7_000_002, name: 'Anthem User Debit Adjustments', kind: :revenue)
#   end

#   context 'Given Customer, Insurer Premium, User Fee and User Fee Adjustment accounts' do
#     context 'and a user fee is entered' do
#       let(:credit_side) { 'credit' }
#       let(:debit_side) { 'debit' }
#       let(:customer_full_premium_amount) { 1000.0 }
#       let(:sbm_user_fee_amount) { (customer_full_premium_amount * 0.03).to_d }
#       let(:customer_discount_premium_amount) { customer_full_premium_amount - sbm_user_fee_amount }
#       let(:zero_initial_balance) { 0.0 }
#       let(:date) { Date.today }

#       let(:sbm_user_fee_credit_entry) do
#         { keepr_account: sbm_user_fee_ar_account, amount: sbm_user_fee_amount, side: credit_side }
#       end
#       let(:hp_insurer_user_fee_debit_entry) do
#         { keepr_account: hp_insurer_user_fee_debit_account, amount: sbm_user_fee_amount, side: debit_side }
#       end

#       let(:hp_insurer_user_fee_credit_entry) do
#         { keepr_account: hp_insurer_user_fee_credit_account, amount: zero_initial_balance, side: credit_side }
#       end

#       let(:credits) { [sbm_user_fee_credit_entry, hp_insurer_user_fee_credit_entry] }
#       let(:debits) { [hp_insurer_user_fee_debit_entry] }
#       let(:account_entry) { { date: date, debits: debits, credits: credits } }

#       let(:keepr_postings_attributes) { [sbm_user_fee_credit_entry, hp_insurer_user_fee_debit_entry] }
#       let(:sbm_user_fee_journal) { Keepr::Journal.create(keepr_postings_attributes: keepr_postings_attributes) }

#       let(:customer_accounts) {
#         premium
#       }
#       let(:carrier_accounts) {{
#         premium_account: premium_account,

#       }}

#       let(:sbm_user_fee_ar_rollup_account)
#       let(:customer_premium_rollup_account)

#       # customer may have 1 or more carriers
#       let(:customer_premium_carrier_journal) { {
#         # account: customer full premium - credit
#         # account: specific carrier 97% of full premium - debit
#         # account: specific carrier 3% user fee of full premium - debit, child of sbm_user_fee_ar_rollup_account
#       } }
#       let(:customer_credit_adjustment_journal) {{}}
#       let(:customer_debit_adjustment_journal) {{}}

#       let(:account) { { number: 3000, name: 'SBM User Fees Accounts Receivable', kind: :revenue } }
#       let(:journal) { { number: 1000, date: Date.new(Date.today.year, 1, 1), subject: '', note: '' } }

#       let(:posting) do
#         {
#           amount: 100,
#           side: 'credit',
#           keepr_account: account,
#           keepr_journal_id: journal.id
#         }
#       end

#       before { sbm_user_fee_journal.update!(permanent: true) }

#       it 'should record an account entry' do
#         result = subject.call(journal: sbm_user_fee_journal)
#         expect(result.success?).to be_truthy
#       end
#     end
#   end
# end
