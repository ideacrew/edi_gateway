# frozen_string_literal: true

module Integrations
  # A single workflow event instance for transmission to an external service
  class Variable
    include Mongoid::Document
    include Mongoid::Timestamps

    field :name, type: String
    field :data_type, type: String # StringifiedHash
    field :value, type: String
  end
end
