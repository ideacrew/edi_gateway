# frozen_string_literal: true

module Reports
  # starts the process to fetch subscribers and coverage information from edi database
  class ReconPreauditProcessor
    send(:include, Dry::Monads[:result, :do])
    send(:include, Dry::Monads[:try])
    send(:include, ::EventSource::Command)
    send(:include, ::EventSource::Logging)

    def call(params)
      _enabled = yield pre_audit_feature_enabled?
      year = params[:year].to_i
      carrier_ids = yield fetch_carrier_ids
      fetch_and_store_coverage_data(carrier_ids, year)
      Success(true)
    end

    private

    def pre_audit_feature_enabled?
      Success(true)

      # if EdiGatewayRegistry.feature_enabled?(:pre_audit_report)
      #   Success(true)
      # else
      #   Failure("Pre audit report should not be run")
      # end
    end

    def fetch_carrier_ids
      Success([ "96667", "48396", "33653", "50165" ])
    end

    def fetch_and_store_coverage_data(carrier_ids, year)
      carrier_ids.each do |carrier_hios_id|
        result = Reports::RequestGdbSubscribersList.new.call({ carrier_hios_id: carrier_hios_id, year: year })
        result.success? ? Success(:ok) : Failure("Unable to generate report for hios_id #{carrier_hios_id}")
      end
    end
  end
end