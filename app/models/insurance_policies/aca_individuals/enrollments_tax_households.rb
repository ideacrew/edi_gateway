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

      belongs_to :tax_household, class_name: 'InsurancePolicies::AcaIndividuals::TaxHousehold'
      accepts_nested_attributes_for :tax_household

      belongs_to :enrollment, class_name: 'InsurancePolicies::AcaIndividuals::Enrollment'
      accepts_nested_attributes_for :enrollment

      has_many :enrolled_members_tax_household_members,
               class_name: 'InsurancePolicies::AcaIndividuals::EnrolledMembersTaxHouseholdMembers'

      field :applied_aptc, type: Money
      field :available_max_aptc, type: Money
      field :household_benchmark_ehb_premium, type: Money
      field :health_product_hios_id, type: String
      field :dental_product_hios_id, type: String
      field :household_health_benchmark_ehb_premium, type: Money
      field :household_dental_benchmark_ehb_premium, type: Money
    end
  end
end
