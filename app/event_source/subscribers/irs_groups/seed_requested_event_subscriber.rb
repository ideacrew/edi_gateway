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

        result = ::Operations::IrsGroups::SeedIrsGroup.new.call(payload)
        if result.success?
          logger.info(
            'OK: :family_update successful and acked'
          )
          ack(delivery_info.delivery_tag)
        else
          logger.error(
            "Error: :family_update; nacked due to:#{result.inspect}"
          )
          nack(delivery_info.delivery_tag)
        end

      rescue Exception => e
        logger.error(
          "Exception: :family_update\n Exception: #{e.inspect}" +
            "\nBacktrace:\n" + e.backtrace.join("\n")
        )
        nack(delivery_info.delivery_tag)
      end
      # rubocop:enable Lint/RescueException
      # rubocop:enable Style/LineEndConcatenation
      # rubocop:enable Style/StringConcatenation
    end
  end
end