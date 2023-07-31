# frozen_string_literal: true

# Specific identifying information about a trading entity.
class TradingProfile
  include Mongoid::Document
  store_in client: :edidb

  embedded_in :trading_partner

  field :profile_code, type: String
  field :profile_name, type: String
end
