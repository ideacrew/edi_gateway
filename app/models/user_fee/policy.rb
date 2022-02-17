# frozen_string_literal: true

module UserFee
  class Policy
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :customer_account, class_name: 'UserFee::CustomerAccount'

    field :exchange_assigned_id, type: String
    field :insurer_assigned_id, type: String
    field :marketplace_segment_id, type: String
    field :service_area_id, type: String
    field :rating_area_id, type: String
    field :start_on, type: Date
    field :end_on, type: Date

    embeds_many :enrolled_members, class_name: 'UserFee::EnrolledMember'

    embeds_one :product, class_name: 'UserFee::Product'
    accepts_nested_attributess_for :product
  end
end
