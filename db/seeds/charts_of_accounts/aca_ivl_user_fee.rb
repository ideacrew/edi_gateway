# frozen_string_literal: true

require 'keepr'

Keepr::Account.create(number: 10, name: 'Customers', kind: 'forward')
Keepr::Account.create(number: 20, name: 'Insurers', kind: 'forward')

## State-based Markatplace Individual Marketplace Insurer-billed User Fee Setup
# Assets (1000 - 1499)
Keepr::Account.create!(number: 1000, name: 'Cash', kind: :asset)
Keepr::Account.create!(number: 1010, name: 'Undeposited Funds', kind: :asset)
Keepr::Account.create!(number: 1020, name: 'Unapplied Funds', kind: :asset)
Keepr::Account.create!(number: 1030, name: 'Checking Account', kind: :asset)
Keepr::Account.create!(number: 1040, name: 'Savings Account', kind: :asset)

Keepr::Account.create!(number: 1100, name: 'Accounts Receivable', kind: :asset)
Keepr::Account.create!(number: 1200, name: 'User Fee Individual Market A/R', kind: :asset)
Keepr::Account.create!(number: 120_001, name: 'Harvard Pilgrim - A/R', parent: account_1200, kind: :asset)
Keepr::Account.create!(number: 120_002, name: 'Anthem - A/R', parent: account_1200, kind: :asset)

# Fixed Assets (1500 - 1599)

# Liabilities (2000 - 2999)
Keepr::Account.create!(number: 2000, name: 'Accounts Payable', kind: :liability)
Keepr::Account.create!(number: 2100, name: 'Credit Card', kind: :liability)

# Equity (3000 - 3999)

# Revenue (Income 4000 - 4999)
Keepr::Account.create!(number: 4100, name: 'User Fees', kind: :revenue)
# Keepr::Account.create!(number: 4100 + <hbx_id>, name: '<hbx_id> - <last_name>, <first_name> - User Fees', parent: account_4000 , kind: :revenue)

Keepr::Account.create!(number: 4200, name: 'Members User Fee Credits/Reductions', kind: :revenue)
# Keepr::Account.create!(number: 4210 + <hbx_id>, name: '<last_name>, <first_name> - <hbx_id> - Credits/Reductions', parent: account_4110 , kind: :revenue)

Keepr::Account.create!(number: 4400, name: 'Late Fees', kind: :revenue)
Keepr::Account.create!(number: 4410, name: 'NSF Fees', kind: :revenue)
Keepr::Account.create!(number: 4420, name: 'Interest Income', kind: :revenue)

# Cost of Goods Sold (Job Costs 5000 - 5999)
Keepr::Account.create!(number: 5100, name: 'Operations Expenses', kind: :forward)
Keepr::Account.create!(number: '51100', name: 'Less Discounts Taken', parent: account_5100, kind: :forward)

# Expenses (Overhead 6000 - 6999)
Keepr::Account.create!(number: 6100, name: 'Bank Charges', kind: :expense)

# Other Income (7000 - 7999)
Keepr::Account.create!(number: 7000, name: 'Service Fee Income', kind: :revenue)

# Other Expenses (8000 - 8999)
Keepr::Account.create!(number: 8100, name: 'Member Full Premiums', kind: :expense)

sbm_accounts = [{ kind: :asset, name: '', number: 1, parent: 'account_0' }]
sbm_journals = []
insurer_accounts = [{ kind: 'asset', name: '', number: 1, parent: 'account_0' }]

# Journals (Ledgers)
general_ledger =
  Keepr::Journal.create keepr_postings_attributes: [
                          { keepr_account: account_1000, amount: 0.00, side: 'credit' },
                          { keepr_account: account_1010, amount: 0.00, side: 'credit' },
                          { keepr_account: account_1100, amount: 0.00, side: 'credit' },
                          { keepr_account: account_1200, amount: 0.00, side: 'credit' },
                          { keepr_account: account_4000, amount: 0.00, side: 'credit' },
                          { keepr_account: account_4110, amount: 0.00, side: 'credit' },
                          { keepr_account: account_4400, amount: 0.00, side: 'credit' },
                          { keepr_account: account_4410, amount: 0.00, side: 'credit' },
                          { keepr_account: account_4420, amount: 0.00, side: 'credit' },
                          { keepr_account: account_5200, amount: 0.00, side: 'credit' }
                        ]

ar_sub_ledger =
  Keepr::Journal.create keepr_postings_attributes: [
                          { keepr_account: account_1100, amount: 0.00, side: 'debit' },
                          { keepr_account: account_1200, amount: 0.00, side: 'debit' }
                        ]

ap_sub_ledger =
  Keepr::Journal.create keepr_postings_attributes: [
                          { keepr_account: account_4920, amount: 0.00, side: 'debit' },
                          { keepr_account: account_1576, amount: 0.00, side: 'debit' },
                          { keepr_account: account_1600, amount: 0.00, side: 'credit' }
                        ]
