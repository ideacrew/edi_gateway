# frozen_string_literal: true

module InsurancePolicies
  module AcaIndividuals
    # Every InsuranceAgreement will have one or more TaxHousehold
    # This class constructs TaxHousehold object
    class TaxHousehold
      include Mongoid::Document
      include Mongoid::Timestamps
      include DomainModelHelpers

      Money.default_currency = 'USD'

      belongs_to :tax_houshold_group, class_name: 'InsurancePolicies::AcaIndividuals::TaxHouseholdGroup'

      # embeds_one :aptc_accumulator
      # embeds_one :contribution_accumulator

      field :hbx_id, type: String
      field :is_eligibility_determined, type: Boolean
      field :allocated_aptc, type: Money
      field :max_aptc, type: Money
      field :yearly_expected_contribution, type: Money

      # field :eligibility_determination_hbx_id, Types::String.optional.meta(omittable: true)

      field :start_on, type: Date
      field :end_on, type: Date

      # has_many :enrollments_tax_households, class_name: 'InsurancePolicies::AcaIndividuals::Enrollment'
      has_many :tax_household_members, class_name: 'InsurancePolicies::AcaIndividuals::TaxHouseholdMember'
      accepts_nested_attributes_for :tax_household_members

      def enrollments
        Enrollment.in(id: enrollments_tax_households.pluck(:enrollment_id))
      end
    end
  end
end
