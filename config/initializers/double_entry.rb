require 'double_entry'

DoubleEntry.configure do |config|
  # Use json(b) column in double_entry_lines table to store metadata instead of separate metadata table
  config.json_metadata = true

  config.define_accounts do |accounts|
    customer_account_scope =
      lambda(customer_account) do
        raise 'not a UserFee::CustomerAccount' unless customer_account.instance_of?(UserFee::CustomerAccount)
        person.id
      end
    accounts.define(identifier: :user_fee, scope_identifier: customer_account_scope)

    vendor_scope =
      lambda(vendor) do
        raise 'not a Vendor' unless vendor.instance_of?(Vendor)
        vendor.id
      end
    accounts.define(identifier: :accounts_receivable, scope_identifier: vendor_scope)
  end

  # config.define_transfers do |transfers|
  #   transfers.define(from: :checking, to: :savings,  code: :deposit)
  #   transfers.define(from: :savings,  to: :checking, code: :withdraw)
  # end
end
