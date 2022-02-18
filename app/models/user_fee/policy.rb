# frozen_string_literal: true

module UserFee
  class Policy
    include Mongoid::Document
    include Mongoid::Timestamps

    belongs_to :customer_account, class_name: 'UserFee::CustomerAccount'

    field :exchange_assigned_id, type: String
    field :insurer_assigned_id, type: String
    field :marketplace_segment_id, type: String
    field :service_area_id, type: String
    field :rating_area_id, type: String
    field :start_on, type: Date
    field :end_on, type: Date

    embeds_one :insurer, class_name: 'UserFee::Insurer'
    embeds_one :product, class_name: 'UserFee::Product'
    has_many :marketplace_segments, class_name: 'UserFee::MarketplaceSegment'
    accepts_nested_attributes_for :product, :marketplace_segments
  end
end
