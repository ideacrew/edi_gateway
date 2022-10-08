# frozen_string_literal: true

# Represents an insurance carrier.
class Carrier
  include Mongoid::Document
  store_in client: :edidb

  field :name, type: String
  field :hbx_carrier_id, type: String	# internal ID for carrier

  embeds_many :carrier_profiles

  index({ name: 1 })
  index({ hbx_carrier_id: 1 })
  index({"carrier_profiles.fein" => 1})

  def self.ids_for_token_carriers(names)
    return [] if names.blank?

    search_names = names.map(&:downcase).map { |n| Regexp.compile(n, true) }
    where("name" => { "$in" => search_names }).map(&:id)
  end

  def fein
    carrier_profiles.first.fein
  end
end
