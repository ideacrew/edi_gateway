# frozen_string_literal: true

module Integrations
  # A single workflow event instance for transmission to an external service
  class Head
    include Mongoid::Document
    include Mongoid::Timestamps

    DEFAULT_HEADERS = { correlation_id: 'string', length: 'integer' }.freeze

    embeds_many :variables, as: :headers
  end
end
