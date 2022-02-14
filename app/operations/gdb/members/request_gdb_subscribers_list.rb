
require 'dry/monads'
require 'dry/monads/do'

module Gdb
  module Members
    class RequestGdbSubscribersList
      send(:include, Dry::Monads[:result, :do])
      send(:include, Dry::Monads[:try])
      include EventSource::Command

      def call
        user_token = yield fetch_user_token
        glue_subscriber_end_point_payload = yield construct_payload_hash(user_token)
        event = yield build_event(glue_subscriber_end_point_payload)
        subscribers_list = yield call_glue_for_subscribers_list(event, glue_subscriber_end_point_payload)
        result = yield request_policy_information_for_list(subscribers_list)

        Success(true)
      end

      private

      def fetch_user_token
        result = Try do
          "vjdfwnKXCiKykDSm4rW_"
        end

        return Failure("Failed to find setting: :gluedb_integration, :gluedb_user_access_token") if result.failure?
        result.nil? ? Failure(":gluedb_user_access_token cannot be nil") : result
      end

      def construct_payload_hash(user_token)
        params = { year: Date.today.year == 2021 ? 2022 : Date.today.year,
                   hios_id: "33653",
                   user_token: user_token,
                   start_time: Time.now,
                   end_time: Time.now + 1.hour}

        Success(params)
      end

      def build_event(payload)
        event("events.gdb.members.subscribers_list_received", attributes: payload.merge!(CorrelationID: "12345"))
      end

      def call_glue_for_subscribers_list(event, payload)
        response = event.publish

        Success(response.body)
      rescue StandardError => _e
        if payload[:hios_id].present?
          Failure("Error getting a response from GDB carrier id: #{payload[:hios_id]}")
        else
          Failure("Error getting a response from GDB for input payload #{payload}")
        end
      end

      def request_policy_information_for_list(subscribers_list)
        subscribers_list.each do |subscriber_id|
          ::Gdb::Members::RequestSubscriberPolicy.new.call({subscriber_id: subscriber_id})
        end
        Success(true)
      end
    end
  end
end
