require 'securerandom'

module Invoices
  module Commands
    class RequestProductInvoice < Sequent::Command
      attrs({
        billing_period_start: DateTime,
        billing_period_end: DateTime,
        product_hios_id: String,
        product_coverage_year: String
      })

      def self.create(product_hios_id, product_coverage_year, billing_period_start, billing_period_end)
        guid = SecureRandom.uuid
        aggregate_id = "rpi_aggregate__#{guid}"
        self.new({
          aggregate_id: aggregate_id,
          product_hios_id: product_hios_id,
          product_coverage_year: product_coverage_year,
          billing_period_start: billing_period_start,
          billing_period_end: billing_period_end
        })
      end
    end

    class RecordProductInvoiceSpanCalculation < Sequent::Command
      attrs({
        product_invoice_aggregate_id: String,
        span_billing_entries: array(::Invoices::ValueObjects::SpanBillingEntry)
      })

      def self.create(opts)
        guid = SecureRandom.uuid
        aggregate_id = "csies_aggregate__#{guid}"
        self.new({
          aggregate_id: aggregate_id,
        }.merge(opts))
      end
    end
  end
end