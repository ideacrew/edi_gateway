# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Tax1095a
  # Publish class will build event and publish the payload
  class PublishFamilyPayload
    include Dry::Monads[:result, :do, :try]
    include EventSource::Command

    TRANSMISSION_KINDS = ['h41', '1095a', 'all'].freeze

    MAP_FORM_TYPE_TO_EVENT = {
      "IVL_TAX" => "initial_payload_generated",
      "IVL_VTA" => "void_payload_generated",
      "Corrected_IVL_TAX" => "corrected_payload_generated",
      "IVL_CAP" => "catastrophic_payload_generated"
    }.freeze

    def call(params)
      values = yield validate(params)
      events = yield build_events(values)
      result = yield publish(event)

      Success(result)
    end

    private

    def validate(params)
      errors = []
      params[:transmission_kind] ||= 'all'

      errors << "tax_year required" unless params[:tax_year]
      errors << "tax_form_type required" unless params[:tax_form_type]
      errors << "cv3_payload required" unless params[:cv3_payload]
      errors << "transmission_kind should be one of #{TRANSMISSION_KINDS.join(',')}" unless TRANSMISSION_KINDS.include?(params[:transmission_kind])

      errors.empty? ? Success(params) : Failure(errors)
    end

    def build_events(values)
      events = []

      if ['h41', 'all'].include?(values[:transmission_kind])
        events << event("events.h41.report_items.created", attributes: {
          tax_year: values[:tax_year],
          tax_form_type: values[:tax_form_type],
          cv3_family: values[:cv3_payload]
        }).success
      end

      if ['1095a', 'all'].include?(values[:transmission_kind])
        event_name = MAP_FORM_TYPE_TO_EVENT[values[:tax_form_type]]
        events << event("events.families.tax_form1095a.#{event_name}", attributes: {
          tax_year: values[:tax_year],
          tax_form_type: values[:tax_form_type],
          cv3_payload: values[:cv3_payload]
        }).success
      end

      Success(events)
    end

    def publish(events)
      events.each{|e| e.publish }

      Success("Successfully published the payload for event: #{events.map(&:name)}")
    end
  end
end
