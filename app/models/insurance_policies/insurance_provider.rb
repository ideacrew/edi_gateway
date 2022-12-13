# frozen_string_literal: true

module InsurancePolicies
  # A carrier who offers insurance policy products
  class InsuranceProvider
    include Mongoid::Document
    include Mongoid::Timestamps
    include DomainModelHelpers

    has_many :insurance_products, class_name: 'InsurancePolicies::InsuranceProduct'

    field :title, type: String
    field :hios_id, type: String
    field :description, type: String
    field :text, type: String
    field :fein, type: String

    # has_many :aca_individuals_insurance_agreements,
    #          class_name: 'InsurancePolicies::AcaIndividuals::InsuranceAgreement',
    #          inverse_of: :insurance_provider
  end
end
