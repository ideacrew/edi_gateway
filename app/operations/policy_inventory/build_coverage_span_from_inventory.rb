# frozen_string_literal: true

module PolicyInventory
  # Import an outside span snapshot.
  class BuildCoverageSpanFromInventory
    send(:include, Dry::Monads[:result, :do])

    def call(params)
      cs_params = yield validate_params(params)
      build_coverage_span(cs_params)
    end

    def validate_params(params)
      param_result = PolicyInventory::ImportSpanRecordContract.new.call(params)
      param_result.success? ? Success(param_result.values) : Failure(param_result.errors)
    end

    def build_coverage_span(params)
      enrollees = params[:coverage_span][:enrollees].map do |en_hash|
        ::Policies::ValueObjects::Enrollee.new(en_hash)
      end
      span_params = params[:coverage_span].except(:enrollees)
      coverage_span = ::Policies::ValueObjects::CoverageSpan.new(span_params.merge({enrollees: enrollees}))
      coverage_span.valid? ? Success(coverage_span) : Failure(coverage_span.errors)
    end
  end
end