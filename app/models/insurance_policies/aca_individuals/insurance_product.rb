# frozen_string_literal: true

module InsurancePolicies
  module AcaIndividuals
    class InsuranceProduct
      include Mongoid::Document
      include Mongoid::Timestamps

      field :name, type: String

      embedded_in :insurance_provider, class_name: "InsurancePolicies::AcaIndividuals::InsuranceProvider"
      embeds_many :insurance_product_features, class_name: "InsurancePolicies::AcaIndividuals::InsuranceProductFeature",
                                               cascade_callbacks: true
    end
  end
end
