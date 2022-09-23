# frozen_string_literal: true

require 'keepr'

## State-based Markatplace Individual Marketplace Insurer-billed User Fee Setup
# Assets (1000 - 1499)
Keepr::Account.create!(number: 1000, name: 'Cash', kind: :asset)
Keepr::Account.create!(number: 1010, name: 'Bank Accounts', kind: :asset)

Keepr::Account.create!(number: 1100, name: 'Accounts Receivable', kind: :asset)
Keepr::Account.create!(number: 1200, name: 'User Fee Individual Market Accounts Receivable', kind: :asset)
Keepr::Account.create!(
  number: '120096667',
  name: 'Harvard Pilgrim - 96667 - Accounts Receivable',
  parent: account_1200,
  kind: :asset
)

# Keepr::Account.create!(number: 1200002, name: '<id> - <name> Accounts Receivable', parent: account_1200 , kind: :asset)

# Keepr::Account.create!(number: 1300, name: 'Individual Market Accounts Receivable', kind: :asset)
# Keepr::Account.create!(number: 1310, name: 'SHOP Market Accounts Receivable', kind: :asset)
# Keepr::Account.create!(number: 1320, name: 'Congress Accounts Receivable', kind: :asset)

# Fixed Assets (1500 - 1599)

# Liabilities (2000 - 2999)
# Keepr::Account.create!(number: 2000, name: 'Insurers Accounts Payable', kind: :liability)
# Keepr::Account.create!(number: 2000001, name: '<id> - <name> - Insurer Accounts Payable', parent: account_2000 , kind: :liability)
# Keepr::Account.create!(number: 2100, name: 'Unapplied Payments', kind: :liability)

# Equity (3000 - 3999)

# Revenue (Income 4000 - 4999)
Keepr::Account.create!(number: 4000, name: 'Members User Fees', kind: :revenue)
# Keepr::Account.create!(number: 4000 + <hbx_id>, name: '<hbx_id> - <last_name>, <first_name> - User Fees', parent: account_4000 , kind: :revenue)

Keepr::Account.create!(number: 4110, name: 'Members User Fee Credits/Reductions', kind: :revenue)
# Keepr::Account.create!(number: 4110 + <hbx_id>, name: '<last_name>, <first_name> - <hbx_id> - Credits/Reductions', parent: account_4110 , kind: :revenue)

# Keepr::Account.create!(number: 4200, name: 'Insurance Premiums', kind: :revenue)
# Keepr::Account.create!(number: 4210, name: 'Insurance Premium Credits/Reductions', kind: :revenue)

Keepr::Account.create!(number: 4400, name: 'Late Fees', kind: :revenue)
Keepr::Account.create!(number: 4410, name: 'NSF Fees', kind: :revenue)
Keepr::Account.create!(number: 4420, name: 'Interest Income', kind: :revenue)

# Cost of Goods Sold (Job Costs 5000 - 5999)

# Expenses (Overhead 6000 - 6999)
# Keepr::Account.create!(number: 5000, name: 'Insurer Dispersements', kind: :expense)
# Keepr::Account.create!(number: 5000<hios_id>, name: '<name> Insurer Dispersements', parent: account_5000 , kind: :expense)

# Keepr::Account.create!(number: 5100, name: 'Broker Commissions', kind: :expense)
# Keepr::Account.create!(number: 5000<npn>, name: '<name> Broker Dispersements', parent: account_5000 , kind: :expense)

Keepr::Account.create!(number: 6200, name: 'Bank Charges', kind: :expense)

# Other Income (7000 - 7999)

# Other Expenses (8000 - 8999)

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
