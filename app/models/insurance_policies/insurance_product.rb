# frozen_string_literal: true

module InsurancePolicies
  # A Product
  class InsuranceProduct
    include Mongoid::Document
    include Mongoid::Timestamps
    include DomainModels::Domainable

    # TODO: Confirm what to do
    # belongs_to :plan_years_products

    field :name, type: String
    field :title, type: String
    field :description, type: String
    field :hios_plan_id, type: String
    field :coverage_type, type: String
    field :metal_level, type: String
    field :market_type, type: String
    field :ehb, type: BigDecimal, default: 0.0
    field :plan_year, type: Integer

    belongs_to :insurance_provider, class_name: 'InsurancePolicies::InsuranceProvider'

    # TODO: Confirm with Dan (inside or outisde aca_individuals structure)
    # embeds_many :insurance_product_features,
    #             class_name: "InsurancePolicies::AcaIndividuals::InsuranceProductFeature",
    #             cascade_callbacks: true
  end
end
