# frozen_string_literal: true

module UserFee
  # A
  class Member
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :customer_account, as: :customer, class_name: 'UserFee::CustomerAccount'
    belongs_to :enrolled_member, class_name: 'UserFee::EnrolledMember'

    field :hbx_id, type: String
    field :insurer_assigned_id, type: String
    field :first_name, type: String
    field :last_name, type: String
    field :tax_household_id, type: String
    field :is_tobacco_user, type: Boolean
  end
end
