# frozen_string_literal: true

module UserFee
  class MarketplaceSegment
    include Mongoid::Document
    include Mongoid::Timestamps

    field :subscriber_hbx_id, type: String
    field :policy_id, type: String
    field :start_on, type: Date
    field :end_on, type: Date
    field :segment, type: String

    belongs_to :policy, class_name: 'UserFee::Policy'
    has_many :enrolled_members, class_name: 'UserFee::EnrolledMember'
  end
end
