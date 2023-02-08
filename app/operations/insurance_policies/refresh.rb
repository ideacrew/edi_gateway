# frozen_string_literal: true

module InsurancePolicies
  # Process 'enroll.insurance_policies.refresh_requested' event
  class Refresh
    include Dry::Monads[:result, :do]
    include EventSource::Command

    # TODO: Implement business logic
    def call(params)
      refresh_period = yield validate(params)
      event          = yield build_event(refresh_period)
      result         = yield publish(event)

      Success(result)
    end

    private

    def build_event(_refresh_period)
      event('events.families.find_by_requested', attributes: { person_hbx_id: 10239, year: 2022 })
    end

    def parsed_refresh_period(params)
      Range.new(*params['refresh_period'].split('..').map(&:to_time))
    end

    def publish(event)
      event.publish
      Success("Successfully published event: #{event.name}")
    end

    def validate(params)
      Success(
        parsed_refresh_period(params)
      )
    end
  end
end
