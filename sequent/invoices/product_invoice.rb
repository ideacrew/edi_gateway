module Invoices
  class ProductInvoice < Sequent::AggregateRoot
    def initialize(command)
      super(command.aggregate_id)
      billing_intervals = calculate_billing_intervals(command)
      apply(
        ::Invoices::Events::ProductInvoiceRequested,
        {
          billing_period_start: command.billing_period_start,
          billing_period_end: command.billing_period_end,
          product_hios_id: command.product_hios_id,
          product_coverage_year: command.product_coverage_year,
          billing_intervals: billing_intervals
        }
      )
    end

    def calculate_billing_intervals(command)
      intervals = []
      date_start = command.billing_period_start
      date_end = command.billing_period_end
      while (MonthlyDateUtilities.end_of_month_for(date_start) != command.billing_period_end)
        intervals << ::Invoices::ValueObjects::BillingInterval.new({
          interval_start: date_start,
          interval_end: MonthlyDateUtilities.end_of_month_for(date_start)
        })
        date_start = MonthlyDateUtilities.end_of_month_for(date_start).next_day
      end
      intervals << ::Invoices::ValueObjects::BillingInterval.new({
        interval_start: date_start,
        interval_end: command.billing_period_end
      })
      intervals
    end

    on ::Invoices::Events::ProductInvoiceRequested do |event|
      @billing_period_start = event.billing_period_start
      @billing_period_end = event.billing_period_end
      @product_hios_id = event.product_hios_id
      @product_coverage_year = event.product_coverage_year
      @billing_intevals = event.billing_intervals
    end
  end
end