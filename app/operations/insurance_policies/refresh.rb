# frozen_string_literal: true

module InsurancePolicies
  # Process 'enroll.insurance_policies.refresh_requested' event
  class Refresh
    include Dry::Monads[:result, :do]
    # include EventSource::Command

    # TODO: Implement business logic
    def call(params)
      refresh_period = yield validate(params)
      result         = yield refresh(refresh_period)

      Success(result)
    end

    private

    def parsed_refresh_period(params)
      Range.new(*params['refresh_period'].split('..').map(&:to_time))
    end

    def refresh(_refresh_period)
      Success('Successfully processed event: enroll.insurance_policies.refresh_requested')
    end

    def validate(params)
      Success(
        parsed_refresh_period(params)
      )
    end
  end
end
