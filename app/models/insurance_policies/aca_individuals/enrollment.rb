# frozen_string_literal: true

module InsurancePolicies
  module AcaIndividuals
    # An instance of insurance coverage under a single policy term for a group of enrolled members
    class Enrollment
      include Mongoid::Document
      include Mongoid::Timestamps
      include DomainModelHelpers

      has_many :enrollments_tax_households, class_name: 'InsurancePolicies::AcaIndividuals::EnrollmentsTaxHouseholds'
      accepts_nested_attributes_for :enrollments_tax_households

      embeds_one :subscriber, class_name: 'AcaIndividuals::EnrolledMember', inverse_of: :subscriber_member
      embeds_many :dependents, class_name: 'AcaIndividuals::EnrolledMember', inverse_of: :dependent_member

      field :total_premium, type: Money
      field :total_premium_adjustments, type: Money
      field :total_responsible_premium, type: Money

      field :effectuated_on, type: Date

      field :start_on, type: Date
      field :end_on, type: Date

      def tax_households
        InsurancePolicies::AcaIndividuals::EnrollmentsTaxHouseholds.in(
          id: enrollments_tax_households.pluck(:tax_household_id)
        )
      end
    end
  end
end
