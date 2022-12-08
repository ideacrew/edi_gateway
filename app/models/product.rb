# frozen_string_literal: true

module Products
  # product reference
  class Product
    include Mongoid::Document
    include Mongoid::Timestamps

    field :hios_id, type: String
    field :name, type: String
    field :active_year, type: Integer
    field :metal_level, type: String
    field :benefit_market_kind, type: String
    field :product_kind, type: String
    field :ehb_percent, type: String
    field :pediatric_dental_ehb, type: String
    field :is_dental_only, type: Boolean
    field :primary_enrollee, type: Float
    field :primary_enrollee_one_dependent, type: Float
    field :primary_enrollee_many_dependent, type: Float
  end
end
