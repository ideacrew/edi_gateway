# frozen_string_literal: true

module InsurancePolicies
  module AcaIndividuals
    class EnrollmentsTaxHouseholds
      include Mongoid::Document
      include Mongoid::Timestamps
      include DomainModelHelpers

      Money.default_currency = 'USD'

      belongs_to :tax_household, class_name: 'InsurancePolicies::AcaIndividuals::TaxHousehold'
      accepts_nested_attributes_for :tax_household

      # belongs_to :enrollment
      # accepts_nested_attributes_for :enrollment

      # has_one :health_product
      # has_one :dental_product

      field :household_health_benchmark_ehb_premium, type: Money
      field :household_dental_benchmark_ehb_premium, type: Money
      field :household_benchmark_ehb_premium, type: Money
      field :applied_aptc, type: Money
      field :available_max_aptc, type: Money

      # field :irs_group_id, type: String
    end
  end
end
