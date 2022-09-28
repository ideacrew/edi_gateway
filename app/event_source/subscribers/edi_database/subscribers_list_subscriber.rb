# frozen_string_literal: true

module Subscribers
  # Receive response from Glue
  module EdiDatabase
    class SubscribersListSubscriber
      include ::EventSource::Subscriber[http: '/api/event_source/enrolled_subjects']
      extend EventSource::Logging

      subscribe(:on_api_event_source_enrolled_subjects) do |body, status, headers|
        if status.to_s == "200"
          logger.info "Received response #{status}, Body - #{body}, Headers - #{headers}"
          persist(body)
        else
          logger.error "Unable to receive response status #{status} Body - #{body}, Headers - #{headers}"
        end
      rescue StandardError => e
        logger.error "error backtrace: #{e.inspect}, #{e.backtrace}"
      end

      def self.persist(body)
        params = { subscribers_list: JSON.parse(body) }

        result = Reports::StoreSubscribersList.new.call(params.deep_symbolize_keys!)
        message = if result.success?
                    result.success
                  else
                    result.failure
                  end
        logger.info "Persist : #{message}"
      rescue StandardError => e
        logger.info "subscriber list error message: #{e.backtrace}"
      end
    end
  end
end
