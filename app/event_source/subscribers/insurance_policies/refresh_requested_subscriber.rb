# frozen_string_literal: true

module Subscribers
  module InsurancePolicies
    # Subscriber will receive a request(from enroll) to refresh insurance policies
    class RefreshRequestedSubscriber
      include ::EventSource::Subscriber[amqp: 'enroll.insurance_policies']

      subscribe(:on_refresh_requested) do |delivery_info, _properties, response|
        logger.info "on_refresh_requested response: #{response}"
        subscriber_logger = subscriber_logger_for(:on_insurance_policies_refresh_requested)
        response = JSON.parse(response, symbolize_names: true)
        logger.info "on_refresh_requested response: #{response}"
        subscriber_logger.info "on_refresh_requested response: #{response}"

        process_refresh_requested_event(subscriber_logger, response) unless Rails.env.test?

        ack(delivery_info.delivery_tag)
      rescue StandardError, SystemStackError => e
        logger.info "on_refresh_requested error: #{e} backtrace: #{e.backtrace}; acked (nacked)"
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

      def process_refresh_requested_event(subscriber_logger, response)
        subscriber_logger.info "process_refresh_requested_event: ------- start"
        result = ::InsurancePolicies::Refresh.new.call({ refresh_period: response[:header][:refresh_period] })

        if result.success?
          message = result.success
          subscriber_logger.info "on_refresh_requested acked #{message.is_a?(Hash) ? message[:event] : message}"
        else
          subscriber_logger.info "process_refresh_requested_event: failure: #{error_messages(result)}"
        end
        subscriber_logger.info "process_refresh_requested_event: ------- end"
      rescue StandardError => e
        subscriber_logger.info "process_refresh_requested_event: error: #{e} backtrace: #{e.backtrace}"
        subscriber_logger.info "process_refresh_requested_event: ------- end"
      end

      def subscriber_logger_for(event)
        Logger.new("#{Rails.root}/log/#{event}_#{Date.today.in_time_zone('Eastern Time (US & Canada)').strftime('%Y_%m_%d')}.log")
      end
    end
  end
end
