# frozen_string_literal: true

module Integrations
  # A single workflow event instance for transmission to an external service
  class Event
    include Mongoid::Document
    include Mongoid::Timestamps

    # embeds_one :head
    embedded_in :eventable, polymorphic: true # polyclass_name: ":DataStores::ContractHolderSubject"

    field :name, type: String
    field :body, type: String
    field :status, type: Symbol
    field :error_messages, type: Array
    field :timestamp, type: DateTime, default: -> { Time.now }

    def transmitted?
      status == :transmitted
    end

    def errored?
      status == :errored
    end
  end
end
