# frozen_string_literal: true

module InsurancePolicies
  module AcaIndividuals
    # An instance of insurance coverage under a single policy for a group of enrolled members
    class Enrollment
      include Mongoid::Document
      include Mongoid::Timestamps
      include DomainModelHelpers

      embeds_one :subscriber, class_name: 'AcaIndividuals::EnrolledMember', inverse_of: :subscriber_member
      embeds_many :dependents, class_name: 'AcaIndividuals::EnrolledMember', inverse_of: :dependent_member

      field :total_premium, type: Money
      field :total_premium_adjustments, type: Money
      field :total_responsible_premium, type: Money

      field :effectuated_on, type: Date

      field :start_on, type: Date
      field :end_on, type: Date
    end
  end
end
