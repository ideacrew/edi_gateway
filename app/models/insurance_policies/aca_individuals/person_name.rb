# frozen_string_literal: true

module InsurancePolicies
  module AcaIndividuals
    class PersonName
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :member, class_name: 'InsurancePolicies::AcaIndividuals::Member'

      field :first_name, type: String
      field :last_name, type: String
    end
  end
end