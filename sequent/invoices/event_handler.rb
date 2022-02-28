module Invoices
  class EventHandler < Sequent::Workflow
    on ::Invoices::Events::ProductInvoiceRequested do |event|
      after_commit do
        event.billing_intervals.each do |interval|
          RequestProductBillingCalculationsJob.perform_async(
            event.aggregate_id,
            event.product_hios_id,
            event.product_coverage_year,
            interval.interval_start,
            interval.interval_end
          )
        end
      end
    end
  end
end