# frozen_string_literal: true

module InsurancePolicies
  module AcaIndividuals
    class IrsGroup
      include Mongoid::Document
      include Mongoid::Timestamps
      include DomainModels::Domainable

      has_many :aca_individual_insurance_policies,
               class_name: 'InsurancePolicies::AcaIndividuals::InsurancePolicy',
               inverse_of: :irs_group

      # belongs_to :aca_individual_insurance_policies_irs_groups,
      #            class_name: 'InsurancePolicies::AcaIndividuals::InsurancePolicy'
      #
      #
      # has_many :aca_individual_insurance_policies_irs_groups
      # # accepts_nested_attributes_for :insurance_policy

      has_many :tax_household_groups, class_name: 'InsurancePolicies::AcaIndividuals::TaxHouseholdGroup'
      # accepts_nested_attributes_for :tax_household_group

      field :irs_group_id, type: String
      field :start_on, type: Date
      field :end_on, type: Date
    end
  end
end
