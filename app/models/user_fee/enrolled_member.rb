# frozen_string_literal: true

module UserFee
  class EnrolledMember
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :marketplace_segment, class_name: 'UserFee::MarketplaceSegment'

    field :start_on, type: Date
    field :end_on, type: Date

    has_one :member, class_name: 'UserFee::Member'
    embeds_one :premium, class_name: 'UserFee::Premium'
    accepts_nested_attributes_for :premium
  end
end
