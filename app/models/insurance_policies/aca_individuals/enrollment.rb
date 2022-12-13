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

      belongs_to :insurance_policy, class_name: "InsurancePolicies::AcaIndividuals::InsurancePolicy"

      embeds_one :subscriber, class_name: 'AcaIndividuals::EnrolledMember', as: :subscriber_member
      embeds_many :dependents, class_name: 'AcaIndividuals::EnrolledMember', as: :dependent_members

      field :hbx_enrollment_id, type: String
      field :total_premium_amount, type: Money
      field :total_premium_adjustment_amount, type: Money
      field :total_responsible_premium_amount, type: Money
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
