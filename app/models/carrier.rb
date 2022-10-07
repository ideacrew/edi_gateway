# frozen_string_literal: true

# Represents an insurance carrier.
class Carrier
  include Mongoid::Document
  store_in client: :edidb

  field :name, type: String
  field :abbrev, as: :abbreviation, type: String
  field :hbx_carrier_id, type: String	# internal ID for carrier
  field :ind_hlt, as: :individual_market_health, type: Boolean, default: false
  field :ind_dtl, as: :individual_market_dental, type: Boolean, default: false
  field :shp_hlt, as: :shop_market_health, type: Boolean, default: false
  field :shp_dtl, as: :shop_market_dental, type: Boolean, default: false

  has_many :plans
  embeds_many :carrier_profiles

  index({ name: 1 })
  index({ hbx_carrier_id: 1 })
  index({ "carrier_profiles.fein" => 1 })

  def self.ids_for_token_carriers(names)
    return [] if names.blank?

    search_names = names.map(&:downcase).map { |n| Regexp.compile(n, true) }
    where("name" => { "$in" => search_names }).map(&:id)
  end
end
