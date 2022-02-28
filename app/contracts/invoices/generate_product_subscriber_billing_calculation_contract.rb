module Invoices
  class GenerateProductSubscriberBillingCalculationContract < ::Dry::Validation::Contract
    params do
      required(:product_invoice_aggregate_id).filled(:string)
      required(:product_hios_id).filled(:string)
      required(:product_coverage_year).filled(:string)
      required(:billing_interval_start).filled(:date_time)
      required(:billing_interval_end).filled(:date_time)
    end
  end
end