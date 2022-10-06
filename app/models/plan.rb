# frozen_string_literal: true

class Plan
  include Mongoid::Document
  store_in client: :edidb

  field :name, type: String
  field :abbrev, as: :abbreviation, type: String
  field :hbx_plan_id, type: String  # internal ID for plan
  field :hios_plan_id, type: String
  field :coverage_type, type: String
  field :metal_level, type: String
  field :market_type, type: String
  field :ehb, as: :ehb_max_as_percent, type: BigDecimal, default: 0.0
  field :year, type: Integer

  belongs_to :carrier

  has_many :policies, :inverse_of => :plan

  index({ name: 1 })
  index({ carrier_id: 1 })
  index({ hbx_plan_id: 1 }, { name: "exchange_plan_id_index" })
  index({ hios_plan_id: 1 }, { unique: false, name: "hios_plan_id_index" })
  index({ coverage_type: 1 })
  index({ metal_level: 1 })
  index({ market_type: 1 })
end
