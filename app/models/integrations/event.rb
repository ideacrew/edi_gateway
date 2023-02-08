# frozen_string_literal: true

module Integrations
  # A single workflow event instance for transmission to an external service
  class Event
    include Mongoid::Document
    include Mongoid::Timestamps

    embeds_one :head

    field :name, type: String
    field :body, type: String
    field :status, type: String
    field :errors, type: Array
    field :timestamp, type: DateTime, default: -> { Time.now }
  end
end
