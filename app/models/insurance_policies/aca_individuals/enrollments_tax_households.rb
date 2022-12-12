# frozen_string_literal: true

module InsurancePolicies
  module AcaIndividuals
    # An index table for many-to-many association between {InsurancePolicies::AcaIndividuals::Enrollments} and
    # {InsurancePolicies::AcaIndividuals::TaxHouseholds}
    class EnrollmentsTaxHouseholds
      include Mongoid::Document
      include Mongoid::Timestamps
      include DomainModelHelpers

      Money.default_currency = 'USD'

      belongs_to :tax_household, class_name: 'InsurancePolicies::AcaIndividuals::TaxHousehold'
      accepts_nested_attributes_for :tax_household

      belongs_to :enrollment, class_name: 'InsurancePolicies::AcaIndividuals::Enrollment'
      accepts_nested_attributes_for :enrollment

      field :applied_aptc, type: Money
      field :available_max_aptc, type: Money
    end
  end
end
