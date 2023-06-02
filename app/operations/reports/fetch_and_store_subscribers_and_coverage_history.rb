# frozen_string_literal: true

module Reports
  # making a call to glue models to fetch subscriber list and coverage info
  class FetchAndStoreSubscribersAndCoverageHistory
    send(:include, Dry::Monads[:result, :do])
    send(:include, Dry::Monads[:try])

    def call(params)
      @year = params[:year]
      hios_id = params[:carrier_hios_id]
      subscribers_list = yield fetch_subscribers_list(hios_id)
      _status = yield store_subscribers_list(subscribers_list, hios_id)
      fetch_and_store_coverage_history(hios_id)
      Success(true)
    end

    private

    def fetch_subscribers_list(hios_id)
      result = SubscriberInventory.subscriber_ids_for(hios_id, @year)
      Success(result)
    rescue StandardError => e
      Rails.logger.error e.message
      Failure("Unable to fetch subscribers list due to #{e.message}")
    end

    def store_subscribers_list(subscribers_list, hios_id)
      subscribers_list.each do |subscriber_id|
        audit_record = AuditReportDatum.where(subscriber_id: subscriber_id, hios_id: hios_id, year: @year).first
        if audit_record.present?
          audit_record.update_attributes(status: "pending", payload: nil)
          audit_record.ard_policies = []
        else
          AuditReportDatum.create!(subscriber_id: subscriber_id,
                                   status: 'pending',
                                   hios_id: hios_id,
                                   report_type: "pre_audit",
                                   year: @year)
        end
      end
      Success(true)
    rescue StandardError => e
      Rails.logger.error e.message
      Failure("Unable to store or parse response due to #{e.message}")
    end

    def remove_existing_audit_datum(hios_id)
      AuditReportDatum.all.where(hios_id: hios_id).delete_all
    end

    def fetch_and_store_coverage_history(hios_id)
      audit_datum = AuditReportDatum.where(hios_id: hios_id, year: @year)
      puts "Total number of record for carrier #{hios_id} is #{audit_datum.count}"
      audit_datum.each do |audit|
        RequestSubscriberCoverageHistoryJob.perform_later(audit.id.to_s, 0)
      end
    end
  end
end
