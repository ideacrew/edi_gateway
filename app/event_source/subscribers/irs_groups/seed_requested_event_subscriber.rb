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
      subscribe(:on_built_requested_seed) do |delivery_info, _properties, payload|
        subscriber_logger = subscriber_logger_for(:on_built_requested_seed)
        parsed_payload = JSON.parse(payload, symbolize_names: true)
        result = ::IrsGroups::SeedIrsGroup.new.call(parsed_payload)
        if result.success?
          subscriber_logger.info(
            "OK: :Created IRS Group successfully and acked for family #{parsed_payload[:payload][:hbx_id]}"
          )
        else
          subscriber_logger.info(
            "Error: Unable to create IRS group; failed for family #{parsed_payload[:payload][:hbx_id]} due to:#{result.inspect}"
          )
        end
        ack(delivery_info.delivery_tag)

      rescue Exception => e
        subscriber_logger.info(
          "Exception: Unable to create IRS group for family #{parsed_payload[:payload][:hbx_id]} \n Exception: #{e.inspect}" +
            "\nBacktrace:\n" + e.backtrace.join("\n")
        )
        ack(delivery_info.delivery_tag)
      end
      # rubocop:enable Lint/RescueException
      # rubocop:enable Style/LineEndConcatenation
      # rubocop:enable Style/StringConcatenation

      private

      def subscriber_logger_for(event)
        Logger.new(
          "#{Rails.root}/log/#{event}_#{Date.today.strftime('%Y_%m_%d')}.log"
        )
      end
    end
  end
end
