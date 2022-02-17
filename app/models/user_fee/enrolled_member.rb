# frozen_string_literal: true

module UserFee
  class EnrolledMember
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :policy, class_name: 'UserFee::Policy'

    field :start_on, type: Date
    field :end_on, type: Date

    embeds_one :member, class_name: 'UserFee::Member'
    embeds_one :premium, class_name: 'UserFee::Premium'
    accepts_nested_attributes_for :member, :premium
  end
end
