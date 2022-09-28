# frozen_string_literal: true

module Subscribers
  # Receive response from Glue
  module EdiDatabase
    class CoverageInformationFromGdbSubscriber
      include ::EventSource::Subscriber[http: '/api/event_source/enrolled_subjects/show']
      extend EventSource::Logging

      subscribe(:on_api_event_source_enrolled_subjects_show) do |body, status, headers|
        if status.to_s == "200"
          logger.info "Received coverage information response #{status}, Body - #{body}, Headers - #{headers}"
        else
          logger.error "Unable to receive response status #{status} Body - #{body}, Headers - #{headers}"
        end
      rescue StandardError => e
        logger.error "error backtrace: #{e.inspect}, #{e.backtrace}"
      end
    end
  end
end
