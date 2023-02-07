# frozen_string_literal: true

module Contacts
  class Email
    include Mongoid::Document
    include Mongoid::Timestamps
    include DomainModels::Domainable

    embedded_in :person, class_name: 'People::Person', inverse_of: :emails

    field :kind, type: String
    field :address, type: String
  end
end
