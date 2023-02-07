# frozen_string_literal: true

module Subscribers
  # Receive family payload from enroll
  module IrsGroups
    # Parse CV3 Family payload
    class GluePolicySubscriber
      send(:include, Dry::Monads[:result, :do])
      include ::EventSource::Subscriber[amqp: 'edi_gateway.edi_database.irs_groups']

      # rubocop:disable Lint/RescueException
      # rubocop:disable Style/LineEndConcatenation
      # rubocop:disable Style/StringConcatenation
      subscribe(:on_policy_and_insurance_agreement_created) do |delivery_info, _properties, payload|
        subscriber_logger = subscriber_logger_for(:on_policy_and_insurance_agreement_created)
        parsed_payload = JSON.parse(payload, symbolize_names: true)
        result = ::IrsGroups::CreateOrUpdateInsuranceAgreement.new.call(parsed_payload)
        if result.success?
          subscriber_logger.info(
            "OK: :Created Insurance_Policy successfully and acked for policy #{parsed_payload[:policy_id]}"
          )
        else
          subscriber_logger.info(
            "Error: Unable to create Insurance_Policy; failed for policy #{parsed_payload[:policy_id]} due to:#{result.inspect}"
          )
        end
        ack(delivery_info.delivery_tag)

      rescue Exception => e
        subscriber_logger.info(
          "Exception: Unable to create Insurance_Policy for policy #{parsed_payload[:policy_id]} \n Exception: #{e.inspect}" +
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
