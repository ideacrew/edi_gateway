# frozen_string_literal: true

module UserFees
  class EnrolledMember
    include Mongoid::Document
    include Mongoid::Timestamps

    field :start_on, type: Date
    field :end_on, type: Date

    embedded_in :marketplace_segment, class_name: '::UserFees::MarketplaceSegment'
    embeds_one :member, class_name: '::UserFees::Member'
    embeds_one :premium, class_name: '::UserFees::Premium'
    accepts_nested_attributes_for :member, :premium
  end
end
