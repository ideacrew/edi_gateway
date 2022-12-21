# frozen_string_literal: true

module People
  # Representation of an individual in the system
  class Person
    include Mongoid::Document
    include Mongoid::Timestamps
    include DomainModels::Domainable

    # embedded_in :member, class_name: 'InsurancePolicies::Member'

    field :person_id, type: String
    field :hbx_id, type: String

    embeds_one :name, class_name: 'People::PersonName', cascade_callbacks: true
    accepts_nested_attributes_for :name

    embeds_many :former_names, class_name: 'People::PersonName', cascade_callbacks: true
    accepts_nested_attributes_for :former_names

    embeds_many :emails, class_name: 'Contacts::Email', cascade_callbacks: true
    accepts_nested_attributes_for :emails, allow_destroy: true

    embeds_many :addresses, class_name: 'Locations::Addresses::StreetAddress', cascade_callbacks: true
    accepts_nested_attributes_for :addresses, allow_destroy: true

    embeds_many :phones, class_name: 'Contacts::Phone', cascade_callbacks: true
    accepts_nested_attributes_for :phones, allow_destroy: true

    def change_name(); end
  end
end
