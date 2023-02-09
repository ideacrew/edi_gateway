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

        process_families_found_by_event(subscriber_logger, response) unless Rails.env.test?

        ack(delivery_info.delivery_tag)
      rescue StandardError, SystemStackError => e
        logger.error "on_found_by error: #{e} backtrace: #{e.backtrace}; acked (nacked)"
        ack(delivery_info.delivery_tag)
      end

      private

      def error_messages(result)
        if result.failure.is_a?(Dry::Validation::Result)
          result.failure.errors.to_h
        else
          result.failure
        end
      end

      def process_families_found_by_event(subscriber_logger, response)
        subscriber_logger.info "process_families_found_by_event: ------- start"
        result = ::InsurancePolicies::CreateOrUpdate.new.call(response)

        if result.success?
          message = result.success
          subscriber_logger.info "on_found_by acked #{message.is_a?(Hash) ? message[:event] : message}"
        else
          subscriber_logger.info "process_families_found_by_event: failure: #{error_messages(result)}"
        end
        subscriber_logger.info "process_families_found_by_event: ------- end"
      rescue StandardError => e
        subscriber_logger.error "process_families_found_by_event: error: #{e} backtrace: #{e.backtrace}"
        subscriber_logger.error "process_families_found_by_event: ------- end"
      end

      def subscriber_logger_for(event)
        Logger.new("#{Rails.root}/log/#{event}_#{Date.today.in_time_zone('Eastern Time (US & Canada)').strftime('%Y_%m_%d')}.log")
      end
    end
  end
end
