# frozen_string_literal: true

module UserFees
  # A party who is an {UserFees::EnrolledMember} or contractually responsible for
  #   {UserFees::CustomerAccount}
  class Member
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :enrolled_member, class_name: '::UserFees::EnrolledMember'
    embeds_one :person_name, class_name: '::UserFees::PersonName', cascade_callbacks: true
    accepts_nested_attributes_for :person_name

    field :account_id, type: String
    field :hbx_id, type: String
    field :insurer_assigned_id, type: String
    field :subscriber_hbx_id, type: String
    field :insurer_assigned_id, type: String
    field :insurer_assigned_subscriber_id, type: String
    field :relationship_code, type: String
    field :ssn, type: String
    field :dob, type: Date
    field :gender, type: String
    field :tax_household_id, type: Integer
    field :is_subscriber, type: Boolean
    field :is_tobacco_user, type: Boolean

    def id
      _id.to_s
    end

    def account
      Account.find(self.account_id)
    end
  end
end
