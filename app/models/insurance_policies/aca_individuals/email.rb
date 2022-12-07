# frozen_string_literal: true

module InsurancePolicies
  module AcaIndividuals
    class Email
      include Mongoid::Document
      include Mongoid::Timestamps

      field :kind, type: String
      field :address, type: String

      embedded_in :member, class_name: 'InsurancePolicies::AcaIndividuals::Member'
    end
  end
end
