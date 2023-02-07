# frozen_string_literal: true

# Encapsulates an address.
class Address
  include Mongoid::Document
  store_in client: :edidb

  TYPES = %w(home work mailing).freeze

  field :address_type, type: String
  field :address_1, type: String
  field :address_2, type: String, default: ""
  field :address_3, type: String, default: ""
  field :city, type: String
  field :county, type: String
  field :state, type: String
  field :location_county_code, type: String
  field :location_state_code, type: String
  field :zip, type: String
  field :zip_extension, type: String
  field :country_name, type: String, default: ""
  field :full_text, type: String

  embedded_in :person, :inverse_of => :addresses

  # rubocop:disable Style/StringConcatenation
  def formatted_address
    city_delim = city.present? ? city + "," : city
    line3 = [city_delim, state, zip].reject(&:nil? || empty?).join(' ')
    [address_1, address_2, line3].reject(&:nil? || empty?).join('<br/>').html_safe
  end

  def full_address
    city_delim = city.present? ? city + "," : city
    [address_1, address_2, city_delim, state, zip].reject(&:nil? || empty?).join(' ')
  end
  # rubocop:enable Style/StringConcatenation

  # rubocop:disable Style/YodaCondition
  def home?
    "home" == self.address_type.downcase
  end
  # rubocop:enable Style/YodaCondition
end
