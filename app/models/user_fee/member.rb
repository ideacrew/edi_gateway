# frozen_string_literal: true

module UserFee
  # A
  class Member
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :customer_account, as: :customer, class_name: 'UserFee::CustomerAccount'

    field :hbx_id, type: String
    field :first_name, type: String
    field :last_name, type: String
    field :insurer_assigned_id, type: String
    field :is_tobacco_user, type: Boolean
  end
end
