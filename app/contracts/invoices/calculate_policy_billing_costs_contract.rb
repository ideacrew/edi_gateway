module Invoices
  class CalculatePolicyBillingCostsContract < ::Dry::Validation::Contract
    params do
      required(:product_invoice_aggregate_id).filled(:string)
      required(:policy_aggregate_id).filled(:string)
      required(:billing_interval_start).filled(:date_time)
      required(:billing_interval_end).filled(:date_time)
    end
  end
end