class CalculatePolicyBillingIntervalCostsJob
  include Sidekiq::Worker

  def perform(
    product_invoice_aggregate_id,
    policy_aggregate_id,
    billing_interval_start,
    billing_interval_end
  )
    ::Invoices::CalculatePolicyBillingCosts.new.call({
      product_invoice_aggregate_id: product_invoice_aggregate_id,
      policy_aggregate_id: policy_aggregate_id,
      billing_interval_start: billing_interval_start,
      billing_interval_end: billing_interval_end
    })
  end
end