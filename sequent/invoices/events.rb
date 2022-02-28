module Invoices
  module Events
    class ProductInvoiceRequested < Sequent::Event
      attrs({
        billing_period_start: DateTime,
        billing_period_end: DateTime,
        product_hios_id: String,
        product_coverage_year: String,
        billing_intervals: array(::Invoices::ValueObjects::BillingInterval)
      })
    end

    class ProductInvoiceSpanCalculationRecorded < Sequent::Event
      attrs({
        product_invoice_aggregate_id: String,
        span_billing_entries: array(::Invoices::ValueObjects::SpanBillingEntry)
      })
    end
  end
end