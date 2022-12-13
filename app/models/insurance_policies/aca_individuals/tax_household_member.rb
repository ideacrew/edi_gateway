# frozen_string_literal: true

module InsurancePolicies
  module AcaIndividuals
    # Every TaxHousehold will have one or more TaxHouseholdMembers
    # This class constructs TaxHouseholdMember object
    class TaxHouseholdMember
      include Mongoid::Document
      include Mongoid::Timestamps
      include DomainModelHelpers

      belongs_to :tax_household, class_name: 'InsurancePolicies::AcaIndividuals::TaxHousehold'

      belongs_to :person, class_name: 'People::Person'
      accepts_nested_attributes_for :person

      field :person_hbx_id, type: String
      field :is_subscriber, type: Boolean, default: false
      field :is_tax_filer, type: Boolean
      field :financial_assistance_applicant, type: Boolean, default: true
      field :reason, type: String
      field :is_ia_eligible, type: Boolean, default: false
      field :is_medicaid_chip_eligible, type: Boolean, default: false
      field :is_totally_ineligible, type: Boolean, default: false
      field :is_uqhp_eligible, type: Boolean, default: false
      field :is_non_magi_medicaid_eligible, type: Boolean, default: false
      field :is_without_assistance, type: Boolean, default: false
      field :tax_filer_status, type: String
      field :slcsp_benchmark_premium, type: Money
      field :relation_with_primary, type: String
    end
  end
end
