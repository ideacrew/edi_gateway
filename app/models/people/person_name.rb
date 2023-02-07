# frozen_string_literal: true

module People
  class PersonName
    include Mongoid::Document
    include Mongoid::Timestamps
    include DomainModels::Domainable

    embedded_in :person, class_name: 'People::Person', inverse_of: :name
    embedded_in :person, class_name: 'People::Person', inverse_of: :former_names

    field :first_name, type: String, as: :given_name
    field :middle_name, type: String
    field :last_name, type: String, as: :family_name
    field :name_pfx, type: String
    field :name_sfx, type: String
    field :alternate_name, type: String
  end
end
