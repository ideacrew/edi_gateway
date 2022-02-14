
require 'dry/monads'
require 'dry/monads/do'

module Gdb
  module Members
    class RequestSubscriberPolicy
      send(:include, Dry::Monads[:result, :do])
      send(:include, Dry::Monads[:try])
      include EventSource::Command

      def call(params)
        validated_params = yield validate(params)
        user_token = yield fetch_user_token
        payload = yield construct_payload_hash(validated_params, user_token)
        event = yield build_event(payload)
        result = yield publish(event, payload)
      end

      private

      def validate(params)
        return Failure("Unable to find subscriber_id") if params[:subscriber_id].blank?

        Success(params)
      end

      def fetch_user_token
        result = Try do
          "vjdfwnKXCiKykDSm4rW_"
        end

        return Failure("Failed to find setting: :gluedb_integration, :gluedb_user_access_token") if result.failure?
        result.nil? ? Failure(":gluedb_user_access_token cannot be nil") : result
      end

      def construct_payload_hash(validated_params, user_token)
        payload =  { year: Date.today.year == 2021 ? 2022 : Date.today.year,
          user_token: user_token,
          subscriber_id: validated_params[:subscriber_id] }
        Success(payload)
      end

      def build_event(payload)
        event("events.gdb.members.member_publisher.gdb_subscriber_policy_requested", attributes: payload.to_h)
      end

      def publish(event, payload)
        event.publish

        Success("Successfully sent request to subscribe")
      rescue StandardError => _e
        if payload[:hios_id].present?
          Failure("Error publishing request for subscriber_id: #{payload[:subscriber_id]}")
        else
          Failure("Error publishing request for  input #{payload}")
        end
      end
    end
  end
end
