# frozen_string_literal: true

module InsurancePolicies
  module AcaIndividuals
    class ResponsibleParty
      include Mongoid::Document
      include Mongoid::Timestamps
      include DomainModels::Domainable

      field :kind, type: String
      field :hbx_id, type: String

      belongs_to :person, class_name: "People::Person", index: true
    end
  end
end
