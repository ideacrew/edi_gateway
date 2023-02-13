# frozen_string_literal: true

module Subscribers
  module Families
    # Subscriber will receive an event(from enroll) with family that is found
    class FoundBySubscriber
      include ::EventSource::Subscriber[amqp: 'enroll.families']

      subscribe(:on_found_by) do |delivery_info, _properties, response|
        logger.info "on_found_by response: #{response}"
        subscriber_logger = subscriber_logger_for(:on_families_found_by)
        response = JSON.parse(response, symbolize_names: true)
        logger.info "on_found_by response: #{response}"
        subscriber_logger.info "on_found_by response: #{response}"

        DataStores::ContractHolderSyncJobs::ProcessResponseEvent.new.call(response)

        ack(delivery_info.delivery_tag)
      rescue StandardError, SystemStackError => e
        logger.error "on_found_by error: #{e} backtrace: #{e.backtrace}; acked (nacked)"
        ack(delivery_info.delivery_tag)
      end

      private

      def error_messages(result)
        result.failure.is_a?(Dry::Validation::Result) ? result.failure.errors.to_h : result.failure
      end

      def subscriber_logger_for(event)
        Logger.new(
          "#{Rails.root}/log/#{event}_#{Date.today.in_time_zone('Eastern Time (US & Canada)').strftime('%Y_%m_%d')}.log"
        )
      end
    end
  end
end
