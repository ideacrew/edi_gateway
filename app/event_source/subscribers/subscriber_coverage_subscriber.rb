# frozen_string_literal: true

module Subscribers
  # Receive response from Glue
  class SubscriberCoverageSubscriber
    include ::EventSource::Subscriber[http: '/subscriber_coverage']
    extend EventSource::Logging

    subscribe(:on_subscriber_coverage) do |body, status, headers|
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
