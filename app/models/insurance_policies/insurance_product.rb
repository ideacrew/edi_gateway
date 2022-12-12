# frozen_string_literal: true

module InsurancePolicies
  # A Product
  class InsuranceProduct
    include Mongoid::Document
    include Mongoid::Timestamps
    include DomainModelHelpers

    belongs_to :plan_years_products
    embeds_many :insurance_product_features

    field :name, type: String
    field :title, type: String
    field :description, type: String

    field :plan_year, type: Integer
  end
end
