# # frozen_string_literal: true

# require 'dry/monads'
# require 'dry/monads/do'

# module UserFees
#   module Accounts
#     # Add a {UserFees::Accounts::UserFee} transaction to one or more Accounts
#     class CreateCustomerAccount
#       send(:include, Dry::Monads[:result, :do])

#       # A/R & Revenue Rollup Accounts and Journal
#       ar_acct = Keepr::Account.create!(number: 1100, name: 'Accounts Receivable', kind: :asset)
#       revenue_acct = Keepr::Account.create!(number: 4000, name: 'Revenue', kind: :revenue)
#       ar_journal = Keepr::Account.create!(number: 1000, date: Date.new(Date.today.year, 1, 1), subject: '', note: '')

#       # All Carriers User Fee A/R & Revenue Accounts & Journal
#       ar_user_fees_acct = Keepr::Account.create!(number: 1110, name: 'User Fees A/R', kind: :asset, parent: ar_acct)
#       revenue_user_fees_acct =
#         Keepr::Account.create!(number: 4110, name: 'User Fees Revenue', kind: :revenue, parent: revenue_acct)
#       ar_user_fees_journal =
#         Keepr::Account.create!(number: 1000, date: Date.new(Date.today.year, 1, 1), subject: '', note: '')

#       # All Carriers User Fee Adjustment A/R & Revenue Accounts & Journal
#       ar_premium_acct = Keepr::Account.create!(number: 4000, name: 'Full Premium Accounts Receivable', kind: :asset)
#       revenue_premium_acct = Keepr::Account.create!(number: 4000, name: 'Full Premium Revenue', kind: :asset)
#       ar_journal = Keepr::Account.create!(number: 1000, date: Date.new(Date.today.year, 1, 1), subject: '', note: '')

#       # All Carriers Full Premium A/R & Revenue Accounts & Journal
#       ar_premium_acct = Keepr::Account.create!(number: 4000, name: 'Full Premium Accounts Receivable', kind: :asset)
#       revenue_premium_acct = Keepr::Account.create!(number: 4000, name: 'Full Premium Revenue', kind: :asset)
#       ar_journal = Keepr::Account.create!(number: 1000, date: Date.new(Date.today.year, 1, 1), subject: '', note: '')

#       # Individual Carrier User Fee A/R & Revenue Accounts & Journal
#       ar_user_fees_hp_acct =
#         Keepr::Account.create!(
#           number: 1_110_001,
#           name: 'Harvard Pilgram User Fees A/R',
#           kind: :asset,
#           parent: ar_user_fees_acct
#         )

#       revenue_user_fees_hp_acct =
#         Keepr::Account.create!(
#           number: 4_110_001,
#           name: 'Harvard Pilgram User Fees Revenue',
#           kind: :revenue,
#           parent: revenue_user_fees_acct
#         )
#       ar_journal = Keepr::Account.create!(number: 1000, date: Date.new(Date.today.year, 1, 1), subject: '', note: '')

#       # Individual Carrier User Fee Adjustment A/R & Revenue Accounts & Journal
#       ar_user_fees_adjustment_acct =
#         Keepr::Account.create!(number: 1110, name: 'User Fees A/R', kind: :asset, parent: ar_acct)
#       revenue_user_fees_adjustment_acct =
#         Keepr::Account.create!(number: 1110, name: 'User Fees A/R', kind: :asset, parent: ar_acct)
#       ar_journal = Keepr::Account.create!(number: 1000, date: Date.new(Date.today.year, 1, 1), subject: '', note: '')

#       # Individual Carrier Full Premium A/R & Revenue Accounts & Journal
#       ar_user_fees_hp_acct =
#         Keepr::Account.create!(
#           number: 1_110_001,
#           name: 'Harvard Pilgram User Fees A/R',
#           kind: :asset,
#           parent: ar_user_fees_acct
#         )

#       ## Account: Carrier X User Fee, Revenue, Credit
#       revenue_user_fees_hp_acct =
#         Keepr::Account.create!(
#           number: 4_110_001,
#           name: 'Harvard Pilgram User Fees Revenue',
#           kind: :revenue,
#           parent: revenue_user_fees_acct
#         )
#       ar_journal = Keepr::Account.create!(number: 1000, date: Date.new(Date.today.year, 1, 1), subject: '', note: '')

#       # Carrier Full Premium A/R Rollup Account
#       revenue_full_premium_racct =
#         Keepr::Account.create!(number: 4000, name: 'User Fees Accounts Receivable', kind: :asset)

#       # Full Premium Journal
#       ## Account: Carrier X Full Premium Income, Revenue, Credit
#       hp_premium_income =
#         Keepr::Account.create!(
#           number: 4_000_001,
#           name: 'Harvard Pilgram Full Premium Revenue',
#           kind: :revenue,
#           parent: ar_revenue_acct
#         )

#       ## Account: Carrier X Full Premium Expense, Expense, Debit

#       # User Fee Adjustments Journal
#       ## Account: Carrier X User Fee Credit Adjustments, Revenue, Credit
#       ## Account: Carrier X User Fee Debit Adjustments, Expense, Debit

#       ar_journal = Keepr::Account.create!(number: 1000, date: Date.new(Date.today.year, 1, 1), subject: '', note: '')

#       def call(params); end
#     end
#   end
# end
