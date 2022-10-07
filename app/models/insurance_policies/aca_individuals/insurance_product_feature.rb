# frozen_string_literal: true

module InsurancePolicies
  module AcaIndividuals
    class InsuranceProductFeature
      include Mongoid::Document
      include Mongoid::Timestamps

      field :key, type: String
      field :title, type: String
      field :description, type: String

      embedded_in :insurance_provider, class_name: "InsurancePolicies::AcaIndividuals::InsuranceProduct"
    end
  end
end
