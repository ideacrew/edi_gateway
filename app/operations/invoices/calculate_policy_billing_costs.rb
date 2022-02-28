module Invoices
  class CalculatePolicyBillingCosts
    send(:include, Dry::Monads[:result, :do, :try])

    def call(params)
      valid_params = yield validate_parameters(params)
      Success(process_policy_and_billing_intervals(valid_params))
    end

    def validate_parameters(params)
      validated_params = ::Invoices::CalculatePolicyBillingCostsContract.new.call(params)
      validated_params.success? ? Success(validated_params.values) : Failure(validated_params.errors)
    end

    def process_policy_and_billing_intervals(params)
      billing_interval_start = params[:billing_interval_start]
      billing_interval_end = params[:billing_interval_end]
      product_invoice_aggregate_id = params[:product_invoice_aggregate_id]
      policy = ::Policies::PolicyRecord.where(
        aggregate_id: params[:policy_aggregate_id]
      ).first
      responsible_individual_id = policy.responsible_party_hbx_id.present? ? policy.responsible_party_hbx_id : policy.subscriber_hbx_id
      qualifying_spans_by_start = policy.coverage_span_records.select do |cs|
        cs.coverage_start <= billing_interval_end
      end
      qualifying_spans_by_end = qualifying_spans_by_start.select do |cs|
        cs.coverage_end.blank? || (cs.coverage_end >= billing_interval_start)
      end
      span_billing_entries = qualifying_spans_by_end.map do |cs|
        date_factor, start_date, end_date = calculate_date_factor(cs, billing_interval_start, billing_interval_end)
        ::Invoices::ValueObjects::SpanBillingEntry.new({
          policy_aggregate_id: policy.aggregate_id,
          coverage_span_id: cs.id,
          coverage_start: start_date.to_datetime,
          coverage_end: end_date.to_datetime,
          billing_interval_start: billing_interval_start,
          billing_interval_end: billing_interval_end,
          total_cost: (cs.total_cost * date_factor),
          applied_aptc: (cs.applied_aptc * date_factor),
          responsible_amount: (cs.responsible_amount * date_factor),
          billed_individual_hbx_id: responsible_individual_id
        })
      end
      command = ::Invoices::Commands::RecordProductInvoiceSpanCalculation.create({
        product_invoice_aggregate_id: product_invoice_aggregate_id,
        span_billing_entries: span_billing_entries
      })
      Sequent.command_service.execute_commands command
    end

    def calculate_date_factor(coverage_span_record, billing_interval_start, billing_interval_end)
      start_date = (coverage_span_record.coverage_start < billing_interval_start) ? billing_interval_start : coverage_span_record.coverage_start
      end_date = billing_interval_end
      if coverage_span_record.coverage_end.present? && (coverage_span_record.coverage_end < billing_interval_end)
        end_date = coverage_span_record.coverage_end
      end
      return [1.0, start_date, end_date] if is_end_of_month?(end_date) && is_start_of_month?(start_date)
      days_interval = (end_date.mday - start_date.mday) + 1
      factor = BigDecimal(days_interval.to_s)/(BigDecimal(month_length(end_date).to_s))
      [factor, start_date, end_date]
    end

    def month_length(date)
      current_date = date
      while (current_date.month == current_date.next_day.month)
        current_date = current_date.next_day
      end
      current_date.mday
    end

    def is_end_of_month?(date)
      date.month != date.next_day.month
    end

    def is_start_of_month?(date)
      date.month != date.prev_day.month
    end
  end
end