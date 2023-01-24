# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

# rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
module Tax1095a
  # Publish class will build event and publish the payload
  class PublishRequest
    include Dry::Monads[:result, :do, :try]
    include EventSource::Command

    REGISTERED_EVENTS = {
      'IVL_TAX' => 'insurance_policies.tax1095a_payload.requested',
      'IVL_VTA' => 'families.tax_form1095a.void_payload_generated',
      'Corrected_IVL_TAX' => 'families.tax_form1095a.corrected_payload_generated',
      'IVL_CAP' => 'families.tax_form1095a.catastrophic_payload_generated'
    }.freeze

    def call(params)
      values = yield validate(params)
      event  = yield build_event(values)
      result = yield publish(event)

      Success(result)
    end

    private

    def validate(params)
      errors = []
      errors << "tax_year required" unless params[:tax_year]
      errors << "tax_form_type required" unless params[:tax_form_type]
      errors << "cv3_payload required" unless params[:cv3_payload]

      errors.empty? ? Success(params) : Failure(errors)
    end

    def build_event(values)
      @event_name = REGISTERED_EVENTS[values[:tax_form_type]]
      event("events.#{@event_name}", attributes: {
              tax_year: values[:tax_year],
              tax_form_type: values[:tax_form_type],
              cv3_payload: values[:cv3_payload]
            })
    end

    def publish(event)
      event.publish

      Success("Successfully published the payload for event: #{@event_name}")
    end
  end
end
# rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity
