# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Gdb
  module Members
    # Operation to make http call to Glue and fetch subscriber coverage information
    class RequestGdbSubscriberPolicy
      send(:include, Dry::Monads[:result, :do])
      send(:include, Dry::Monads[:try])
      include EventSource::Command

      def call(params)
        validated_params = yield validate(params)
        payload = yield construct_payload_hash(validated_params)
        event = yield build_event(payload)
        response = yield publish(event, payload)
        record = yield find_or_create(response, payload)
        Success(record)
      end

      private

      def validate(params)
        return Failure("Missing user token") if params[:user_token].blank?
        return Failure("Missing user token") if params[:year].blank?
        return Failure("Missing user token") if params[:subscriber_id].blank?

        Success(params)
      end

      def construct_payload_hash(validated_params)
        payload = { year: validated_params[:year],
                    user_token: validated_params[:user_token],
                    id: validated_params[:subscriber_id] }

        Success(payload)
      end

      def build_event(payload)
        event("events.gdb.enrolled_subjects.subscriber_coverage_information",
              attributes: payload.merge!(CorrelationID: payload[:subscriber_id]))
      end

      def publish(event, payload)
        response = event.publish
        Success(response)
      rescue StandardError => _e
        if payload[:subscriber_id].present?
          Failure("Error publishing request to fetch Coverage Information for : #{payload[:subscriber_id]}")
        else
          Failure("Error publishing request  to fetch Coverage Information for #{payload}")
        end
      end

      def find_or_create(response, payload)
        return Failure("Unable to get response") if response.status != 200
        # rubocop:disable Style/MultilineBlockChain
        Try() do
          ::AuditReportDatum.where(subscriber_id: payload[:id])
        end.bind do |result|
          if result.empty?
            Success(::AuditReportDatum.create!(subscriber_id: payload[:id],
                                               payload: response.body,
                                               status: "completed"))
          else
            datum = result.first
            datum.update(payload: response.body, status: "completed")
            Success(datum)
          end
        end
        # rubocop:enable Style/MultilineBlockChain
      end
    end
  end
end
