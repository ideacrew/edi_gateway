# frozen_string_literal: true

module Locations
  module Addresses
    class ValidationStatus
      include Mongoid::Document
      include Mongoid::Timestamps
      include ::DomainModelHelpers

      embedded_in :address, class_name: 'InsurancePolicies::Person', inverse_of: :emails

      field :is_valid, type: Boolean
      field :authority, type: String
      field :payload, type: String
      field :validated_at, type: DateTime
    end
  end
end
