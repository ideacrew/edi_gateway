# frozen_string_literal: true

class ResponsibleParty
  include Mongoid::Document
  store_in client: :edidb

  field :entity_identifier, type: String
  field :entity_type, type: String, default: "1"
  field :organization_name, type: String

  embedded_in :person

  has_many :policies, :inverse_of => "responsible_party"
end
