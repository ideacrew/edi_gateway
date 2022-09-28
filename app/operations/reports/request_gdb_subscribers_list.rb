# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Reports
  # Operation to make http call to Glue and fetch subscribers list
  class RequestGdbSubscribersList
    send(:include, Dry::Monads[:result, :do])
    send(:include, Dry::Monads[:try])
    include EventSource::Command

    def call(params)
      hios_id = params[:carrier_hios_id]
      year = params[:year]
      user_token = yield fetch_user_token
      payload = yield construct_payload_hash(user_token, hios_id, year)
      event = yield build_event(payload)
      subscribers_list = yield publish(event, payload)
      _result = yield request_policy_information_for_list(subscribers_list, year)

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

    def construct_payload_hash(user_token, hios_id, year)
      params = { year: year,
                 user_token: user_token,
                 start_time: Time.now,
                 end_time: Time.now + 1.hour,
                 hios_id: hios_id}

      Success(params)
    end

    def build_event(payload)
      event("events.edi_database.enrolled_subjects.subscribers_list", attributes: payload)
    end

    def publish(event, payload)
      binding.irb
      response = event.publish
      Success(response.body)
    rescue StandardError => _e
      if payload[:hios_id].present?
        Failure("Error getting a response from GDB carrier id: #{payload[:hios_id]}")
      else
        Failure("Error getting a response from GDB for input payload #{payload}")
      end
    end

    def request_policy_information_for_list(subscribers_list, year)
      subscribers_list.each do |subscriber_id|
        ::EdiDatabase::Members::RequestSubscriberCoverageInformation.new.call({ subscriber_id: subscriber_id,
                                                                                year: 2022})
      end
      Success(true)
    end
  end
end
