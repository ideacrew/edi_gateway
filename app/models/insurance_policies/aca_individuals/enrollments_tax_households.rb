# frozen_string_literal: true

module InsurancePolicies
  module AcaIndividuals
    # An index table for many-to-many association between {InsurancePolicies::AcaIndividuals::Enrollments} and
    # {InsurancePolicies::AcaIndividuals::TaxHouseholds}
    class EnrollmentsTaxHouseholds
      include Mongoid::Document
      include Mongoid::Timestamps
      include DomainModels::Domainable

      Money.default_currency = 'USD'

      belongs_to :tax_household, class_name: 'InsurancePolicies::AcaIndividuals::TaxHousehold', index: true
      accepts_nested_attributes_for :tax_household

      belongs_to :enrollment, class_name: 'InsurancePolicies::AcaIndividuals::Enrollment', index: true
      accepts_nested_attributes_for :enrollment

      has_many :enrolled_members_tax_household_members,
               class_name: 'InsurancePolicies::AcaIndividuals::EnrolledMembersTaxHouseholdMembers',
               inverse_of: :enrollments_tax_households,
               dependent: :destroy

      field :applied_aptc, type: Money
      field :available_max_aptc, type: Money

      # indexes
      index({ applied_aptc: 1 })
      index({ available_max_aptc: 1 })
      index({ tax_household_id: 1, enrollment_id: 1 })
    end
  end
end
