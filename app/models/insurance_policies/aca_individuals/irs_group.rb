# frozen_string_literal: true

module InsurancePolicies
  module AcaIndividuals
    class IrsGroup
      include Mongoid::Document
      include Mongoid::Timestamps
      include DomainModelHelpers

      belongs_to :insurance_policy, class_name: 'InsurancePolicies::AcaIndividuals::InsurancePolicy'
      accepts_nested_attributes_for :insurance_policy

      belongs_to :tax_household_group, class_name: 'InsurancePolicies::AcaIndividuals::TaxHouseholdGroup'
      accepts_nested_attributes_for :tax_household_group

      field :irs_group_id, type: String
      field :start_on, type: Date
      field :end_on, type: Date
    end
  end
end
