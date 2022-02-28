class RequestProductBillingCalculationsJob
  include Sidekiq::Worker

  def perform(
    product_invoice_aggregate_id,
    product_hios_id,
    product_coverage_year,
    billing_interval_start,
    billing_interval_end
  )
    ::Invoices::GenerateProductSubscriberBillingCalculation.new.call({
      product_hios_id: product_hios_id,
      product_coverage_year: product_coverage_year,
      billing_interval_start: billing_interval_start,
      billing_interval_end: billing_interval_end,
      product_invoice_aggregate_id: product_invoice_aggregate_id
    })
  end
end