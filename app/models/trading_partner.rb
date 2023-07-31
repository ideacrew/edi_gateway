# frozen_string_literal: true

# Represents an entity that receives or sends information.
class TradingPartner
  include Mongoid::Document
  store_in client: :edidb

  field :name, type: String

  embeds_many :trading_profiles
end
