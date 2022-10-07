# frozen_string_literal: true

# Represents carrier profile information, such as FEIN.
class CarrierProfile
  include Mongoid::Document
  include Mongoid::Timestamps
  store_in client: :edidb

  embedded_in :carrier

  field :fein, type: String
  field :profile_name, type: String
end
