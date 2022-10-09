# frozen_string_literal: true

module Subscribers
  # Receive family payload from enroll
  module IrsGroups
    # Parse CV3 Family payload
    class SeedRequestedEventSubscriber
      send(:include, Dry::Monads[:result, :do])
      include ::EventSource::Subscriber[amqp: 'irs_groups.seed_requested']

      # rubocop:disable Lint/RescueException
      # rubocop:disable Style/LineEndConcatenation
      # rubocop:disable Style/StringConcatenation
      subscribe(:on_seed_requested) do |delivery_info, _properties, payload|
        subscriber_logger = subscriber_logger_for(:on_seed_requested)
        parsed_payload = JSON.parse(payload, symbolize_names: true)
        result = ::Operations::IrsGroups::SeedIrsGroup.new.call({ payload: parsed_payload })
        if result.success?
          subscriber_logger.info(
            'OK: :Created IRS Group successfully and acked'
          )
          ack(delivery_info.delivery_tag)
        else
          subscriber_logger.info(
            "Error: Unable to create IRS group; nacked due to:#{result.inspect}"
          )
          nack(delivery_info.delivery_tag)
        end

      rescue Exception => e
        subscriber_logger.info(
          "Exception: Unable to create IRS group\n Exception: #{e.inspect}" +
            "\nBacktrace:\n" + e.backtrace.join("\n")
        )
        nack(delivery_info.delivery_tag)
      end
      # rubocop:enable Lint/RescueException
      # rubocop:enable Style/LineEndConcatenation
      # rubocop:enable Style/StringConcatenation

      private

      def subscriber_logger_for(event)
        Logger.new(
          "#{Rails.root}/log/#{event}_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
        )
      end
    end
  end
end
