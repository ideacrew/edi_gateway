class ResponsibleParty
  include Mongoid::Document

  field :entity_identifier, type: String
  field :entity_type, type: String, default: "1"
  field :organization_name, type: String

  validates_inclusion_of :entity_identifier, in: ["case manager", "key person", "parent", "spouse", "responsible party", "guardian", "ex-spouse"]

  embedded_in :person

  has_many :policies, :inverse_of => "responsible_party"

end
