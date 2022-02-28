module Invoices
  class CoverageSpanInvoiceEntrySet < Sequent::AggregateRoot
    def initialize(command)
      super(command.aggregate_id)
      apply(
        ::Invoices::Events::ProductInvoiceSpanCalculationRecorded,
        {
          product_invoice_aggregate_id: command.product_invoice_aggregate_id,
          span_billing_entries: command.span_billing_entries
        }
      )
    end

    on ::Invoices::Events::ProductInvoiceSpanCalculationRecorded do |event|
    end
  end
end