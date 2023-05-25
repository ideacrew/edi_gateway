# frozen_string_literal: true

module Reports
  # received an event from enroll to start the pre audit processor
  class ReconPreAuditProcessor
    send(:include, Dry::Monads[:result, :do])
    send(:include, Dry::Monads[:try])
    send(:include, ::EventSource::Command)
    send(:include, ::EventSource::Logging)

    def call(params)
      @year = params[:year]
      carrier_ids = yield fetch_carrier_ids
      fetch_and_store_coverage_data(carrier_ids)
      Success(true)
    end

    private

    def fetch_carrier_ids
      carrier_hios_ids = ["96667", "48396", "33653", "50165", "54879"]
      Success(carrier_hios_ids)
    end

    def fetch_and_store_coverage_data(carrier_ids)
      carrier_ids.each do |carrier_hios_id|
        result = Reports::FetchAndStoreSubscribersAndCoverageHistory.new.call({ carrier_hios_id: carrier_hios_id, year: @year })
        result.success? ? Success(:ok) : Failure("Unable to generate report for hios_id #{carrier_hios_id}")
      end
    end
  end
end
