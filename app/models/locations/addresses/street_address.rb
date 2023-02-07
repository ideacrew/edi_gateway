# frozen_string_literal: true

module Locations
  module Addresses
    class StreetAddress
      include Mongoid::Document
      include Mongoid::Timestamps
      include DomainModels::Domainable

      embedded_in :person, class_name: 'InsurancePolicies::Person', inverse_of: :addresses

      field :kind, type: String
      field :street_predirection, type: String
      field :address_1, type: String
      field :address_2, type: String, default: ''
      field :address_3, type: String, default: ''
      field :street_postdirection, type: String
      field :city_name, type: String
      field :state_abbreviation, type: String
      field :zip_code, type: String
      field :zip_plus_four_code, type: String

      field :county_name, type: String
      field :has_fixed_address, type: Boolean
      field :lives_outside_state_temporarily, type: Boolean

      embeds_one :validation_status, class_name: 'Locations::Addresses::ValidationStatus', cascade_callbacks: true
      accepts_nested_attributes_for :validation_status
    end
  end
end
