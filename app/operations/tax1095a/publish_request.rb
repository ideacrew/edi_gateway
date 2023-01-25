# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Tax1095a
  # Publish class will build event and publish the payload
  class PublishRequest
    include Dry::Monads[:result, :do, :try]
    include EventSource::Command

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
      errors << "irs_group_id required" unless params[:irs_group_id]

      errors.empty? ? Success(params) : Failure(errors)
    end

    def build_event(values)
      event("events.insurance_policies.tax1095a_payload.requested", attributes: {
              tax_year: values[:tax_year],
              tax_form_type: values[:tax_form_type],
              irs_group_id: values[:irs_group_id]
            })
    end

    def publish(event)
      event.publish

      Success("Successfully published the payload for event: #{event.name}")
    end
  end
end
