# frozen_string_literal: true

# Requests coverage information for a subscriber from Glue
class RequestSubscriberCoverageHistoryJob < ApplicationJob
  queue_as :default
  send(:include, ::EventSource::Command)
  send(:include, ::EventSource::Logging)
  RETRY_LIMIT = 5

  def perform(audit_report_datum_id, attempt = 0)
    @logger = Logger.new("#{Rails.root}/log/recon_report.log")
    ard_record = AuditReportDatum.find(audit_report_datum_id)
    if attempt > RETRY_LIMIT
      @logger.info "Retry Limit exceeded for subscriber #{ard_record&.subscriber_id}"
      return
    end

    result = Reports::RequestCoverageHistoryForSubscriber.new.call({
                                                                     audit_report_datum: ard_record,
                                                                     logger: @logger
                                                                   })
    if result.success?
      Success("Successfully generated AuditReportDatum policies")
    else
      @logger.info "Failed due to #{result.failure}, and retrying #{attempt} time for subscriber #{ard_record&.subscriber_id}"
      RequestSubscriberCoverageHistoryJob.perform_later(audit_report_datum_id, attempt + 1)
    end
  end
end
