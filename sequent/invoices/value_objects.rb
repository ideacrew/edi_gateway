module Invoices
  module ValueObjects
    class BillingInterval < Sequent::ValueObject
      attrs({
        interval_start: DateTime,
        interval_end: DateTime
      })
    end

    class SpanBillingEntry < Sequent::ValueObject
      attrs({
        policy_aggregate_id: String,
        coverage_span_id: String,
        coverage_start: DateTime,
        coverage_end: DateTime,
        billing_interval_start: DateTime,
        billing_interval_end: DateTime,
        billed_individual_hbx_id: String,
        total_cost: BigDecimal,
        applied_aptc: BigDecimal,
        responsible_amount: BigDecimal
      })
    end
  end
end