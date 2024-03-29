# frozen_string_literal: true

module UserFees
  class Policy
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :customer_account, class_name: '::UserFees::CustomerAccount'

    embeds_one :insurer, class_name: '::UserFees::Insurer', cascade_callbacks: true
    embeds_one :product, class_name: '::UserFees::Product', cascade_callbacks: true
    embeds_many :marketplace_segments, class_name: '::UserFees::MarketplaceSegment', cascade_callbacks: true
    accepts_nested_attributes_for :insurer, :product, :marketplace_segments

    field :exchange_assigned_id, type: String
    field :insurer_assigned_id, type: String
    field :subscriber_hbx_id, type: String
    field :service_area_id, type: String
    field :rating_area_id, type: String
    field :start_on, type: Date
    field :end_on, type: Date

    def to_hash
      values = self.serializable_hash.deep_symbolize_keys.merge(id: id.to_s)
      AcaEntities::Ledger::Contracts::PolicyContract.new.call(values).to_h
    end

    alias to_h to_hash
  end
end
