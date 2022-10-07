# frozen_string_literal: true

module InsurancePolicies
  module AcaIndividuals
    class InsuranceProvider
      include Mongoid::Document
      include Mongoid::Timestamps

      field :title, type: String
      field :hios_id, type: String
      field :description, type: String
      field :text, type: String
      field :fein, type: String

      embedded_in :insurance_agreement, class_name: "InsurancePolicies::AcaIndividuals::InsuranceAgreement"
      embeds_many :insurance_products, class_name: "InsurancePolicies::AcaIndividuals::InsuranceProduct"
    end
  end
end