# frozen_string_literal: true

class Address
  include Mongoid::Document
  store_in client: :edidb

  TYPES = %W(home work mailing)

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
end
