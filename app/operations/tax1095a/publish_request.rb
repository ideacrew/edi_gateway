# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Tax1095a
  # Fetch and publish IRS Groups
  # Publish class will build event and publish the renewal payload
  class PublishRequest
    include Dry::Monads[:result, :do, :try]
    include EventSource::Command

    REGISTERED_EVENTS = %w[insurance_policies.tax1095a_payload.requested
                           families.tax_form1095a.initial_payload_generated
                           families.tax_form1095a.void_payload_generated
                           families.tax_form1095a.corrected_payload_generated
                           families.tax_form1095a.catastrophic_payload_generated].freeze

    def call(params)
      payload = yield validate_input_params(params)
      event = yield build_event(payload)
      result = yield publish(event)

      Success(result)
    end

    private

    def validate_input_params(params)
      return Failure('Missing payload key') unless params.key?(:payload)
      return Failure('Missing event_name key') unless params.key?(:event_name)
      if params[:payload].nil? || !params[:payload].is_a?(Hash)
        return Failure("Invalid value: #{params[:payload]} for key payload, must be a Hash object")
      end
      if params[:event_name].nil? || !params[:event_name].is_a?(String)
        return Failure("Invalid value: #{params[:event_name]} for key event_name, must be an String")
      end
      if REGISTERED_EVENTS.exclude?(params[:event_name])
        return Failure("Invalid event_name: #{params[:event_name]} for key event_name, must be one of #{REGISTERED_EVENTS}")
      end

      @event_name = params[:event_name]

      Success(params[:payload])
    end

    def build_event(payload)
      event("events.#{@event_name}", attributes: payload)
    end

    def publish(event)
      binding.pry
      event.publish

      Success("Successfully published the payload for event: #{@event_name}")
    end
  end
end
