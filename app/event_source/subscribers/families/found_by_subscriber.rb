# frozen_string_literal: true

module Subscribers
  module Families
    # Subscriber will receive an event(from enroll) with family that is found
    class FoundBySubscriber
      include ::EventSource::Subscriber[amqp: 'enroll.families']

      subscribe(:on_found_by) do |delivery_info, properties, response|
        logger = subscriber_logger_for(:on_families_found_by)
        logger.info "on_found_by response: #{response}"
        response = JSON.parse(response, symbolize_names: true)
        logger.info "on_found_by response: payload #{response}"

        result =
          DataStores::ContractHolderSyncJobs::ProcessResponseEvent.new.call(
            correlation_id: properties.correlation_id,
            family: response[:family],
            primary_person_hbx_id: response[:primary_person_hbx_id],
            event_name: 'events.enroll.families.found_by'
          )

        if result.success?
          logger.info 'processed response event successfully'
        else
          logger.error "failed to process response event due to: #{error_messages(result)}"
        end

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
