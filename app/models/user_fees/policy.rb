# frozen_string_literal: true

module UserFees
  class Policy
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :customer_account, class_name: '::UserFees::CustomerAccount'

    field :exchange_assigned_id, type: String
    field :insurer_assigned_id, type: String
    field :subscriber_hbx_id, type: String
    field :service_area_id, type: String
    field :rating_area_id, type: String
    field :start_on, type: Date
    field :end_on, type: Date

    embeds_one :insurer, class_name: '::UserFees::Insurer'
    embeds_one :product, class_name: '::UserFees::Product'
    embeds_many :marketplace_segments, class_name: '::UserFees::MarketplaceSegment'
    accepts_nested_attributes_for :insurer, :product, :marketplace_segments
  end
end
