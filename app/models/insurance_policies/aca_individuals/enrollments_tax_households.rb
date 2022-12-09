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

      # belongs_to :health_product
      # belongs_to :dental_product

      field :applied_aptc, type: Money
      field :available_max_aptc, type: Money

      # field :irs_group_id, type: String
    end
  end
end
