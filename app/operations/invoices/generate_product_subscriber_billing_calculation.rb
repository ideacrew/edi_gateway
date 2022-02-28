module Invoices
  class GenerateProductSubscriberBillingCalculation
    send(:include, Dry::Monads[:result, :do, :try])

    def call(params)
      valid_params = yield validate_parameters(params)
      Success(execute_queries_and_create_jobs(valid_params))
    end

    def validate_parameters(params)
      validated_params = ::Invoices::GenerateProductSubscriberBillingCalculationContract.new.call(params)
      validated_params.success? ? Success(validated_params.values) : Failure(validated_params.errors)
    end

    def execute_queries_and_create_jobs(params)
      ::Policies::PolicyRecord.in_billing_interval_range_with_product(
        params[:product_hios_id],
        params[:product_coverage_year],
        params[:billing_interval_start],
        params[:billing_interval_end]
      ).each do |rec|
        CalculatePolicyBillingIntervalCostsJob.perform_async(
          params[:product_invoice_aggregate_id],
          rec.aggregate_id,
          params[:billing_interval_start],
          params[:billing_interval_end]
        )
      end
    end
  end
end