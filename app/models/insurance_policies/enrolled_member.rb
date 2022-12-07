# frozen_string_literal: true

module InsurancePolicies
  class EnrolledMember
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :enrollment, class_name: 'InsurancePolicy::Enrollment'

    field :account_id, type: String
    field :hbx_id, type: String
    field :subscriber_hbx_id, type: String
    field :insurer_assigned_id, type: String
    field :insurer_assigned_subscriber_id, type: String
    field :dob, type: Date, as: :date_of_birth
    field :gender, type: String

    embeds_one :member, class_name: 'InsurancePolicies::Member', cascade_callbacks: true
    accepts_nested_attributes_for :member

    embeds_one :premium, class_name: 'InsurancePolicies::Premium', cascade_callbacks: true
    accepts_nested_attributes_for :premium
  end
end
