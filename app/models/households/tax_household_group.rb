# frozen_string_literal: true

module Households
  # tax household groups
  class TaxHouseholdGroup
    include Mongoid::Document
    include Mongoid::Timestamps

    field :hbx_id, type: String
    field :start_on, type: Date
    field :end_on, type: Date
    field :assistance_year, type: Integer
    field :source, type: String
    field :source, type: String

    embeds_many :tax_households, class_name: "Households::TaxHousehold", cascade_callbacks: true
    accepts_nested_attributes_for :tax_households, allow_destroy: true
  end
end
