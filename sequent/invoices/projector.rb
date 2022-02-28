module Invoices
  class Projector < Sequent::Projector
    manages_tables ::Invoices::ProductInvoiceRecord, ::Invoices::CoverageSpanInvoiceEntryRecord

    on ::Invoices::Events::ProductInvoiceRequested do |event|
      create_record(
        ::Invoices::ProductInvoiceRecord,
        {
          aggregate_id: event.aggregate_id,
          billing_period_start: event.billing_period_start,
          billing_period_end: event.billing_period_end,
          product_hios_id: event.product_hios_id,
          product_coverage_year: event.product_coverage_year
        }
      )
    end

    on ::Invoices::Events::ProductInvoiceSpanCalculationRecorded do |event|
      event.span_billing_entries.each do |entry|
        create_record(
          ::Invoices::CoverageSpanInvoiceEntryRecord,
          {
            aggregate_id: event.aggregate_id,
            product_invoice_aggregate_id: event.product_invoice_aggregate_id,
            policy_aggregate_id: entry.policy_aggregate_id,
            coverage_span_id: entry.coverage_span_id,
            coverage_start: entry.coverage_start,
            coverage_end: entry.coverage_end,
            billing_interval_start: entry.billing_interval_start,
            billing_interval_end: entry.billing_interval_end,
            billed_individual_hbx_id: entry.billed_individual_hbx_id,
            total_cost: entry.total_cost,
            responsible_amount: entry.responsible_amount,
            applied_aptc: entry.applied_aptc
          }
        )
      end
    end
  end
end