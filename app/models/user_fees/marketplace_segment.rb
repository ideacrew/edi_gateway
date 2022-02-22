# frozen_string_literal: true

module UserFees
  class MarketplaceSegment
    include Mongoid::Document
    include Mongoid::Timestamps

    field :subscriber_hbx_id, type: String
    field :start_on, type: Date
    field :end_on, type: Date
    field :segment, type: String
    field :total_premium_amount, type: BigDecimal
    field :total_premium_responsibility_amount, type: BigDecimal

    embedded_in :policy, class_name: '::UserFees::Policy'
    embeds_many :enrolled_members, class_name: '::UserFees::EnrolledMember'
  end
end
