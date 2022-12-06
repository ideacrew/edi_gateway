# frozen_string_literal: true

module Contacts
  class Phone
    include Mongoid::Document
    include Mongoid::Timestamps
    include DomainModelHelpers

    embedded_in :person, class_name: 'People::Person', inverse_of: :phones

    field :primary, type: Boolean
    field :kind, type: String

    field :country_code, type: String, default: '+1'
    field :area_code, type: String
    field :number, type: String
    field :extension, type: String
  end
end
