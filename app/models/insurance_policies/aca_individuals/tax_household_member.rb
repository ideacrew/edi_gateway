# frozen_string_literal: true

module InsurancePolicies
  module AcaIndividuals
    # Every TaxHousehold will have one or more TaxHouseholdMembers
    # This class constructs TaxHouseholdMember object
    class TaxHouseholdMember
      include Mongoid::Document
      include Mongoid::Timestamps
      include DomainModels::Domainable

      belongs_to :tax_household, class_name: 'InsurancePolicies::AcaIndividuals::TaxHousehold', index: true

      belongs_to :person, class_name: 'People::Person', index: true
      accepts_nested_attributes_for :person

      field :hbx_id, type: String
      field :is_subscriber, type: Boolean, default: false
      field :is_tax_filer, type: Boolean
      field :financial_assistance_applicant, type: Boolean
      field :reason, type: String
      field :is_ia_eligible, type: Boolean
      field :is_medicaid_chip_eligible, type: Boolean
      field :is_totally_ineligible, type: Boolean
      field :is_uqhp_eligible, type: Boolean
      field :is_non_magi_medicaid_eligible, type: Boolean
      field :is_without_assistance, type: Boolean

      field :relation_with_primary, type: String
      field :tax_filer_status, type: String

      # indexes
      index({ hbx_id: 1 })
      index({ tax_filer_status: 1 })
      index({ is_subscriber: 1 })
      index({ is_ia_eligible: 1 })
      index({ relation_with_primary: 1 })
      index({ relation_with_primary: 1 })
      index({ person_id: 1, tax_household: 1 })


      # TODO: rename slcsp_benchmark_premium to slcsp_benchmark_premium_amount and use
      # in Enrollment model (THHs will not show up in UQHP CV3s)
      # field :slcsp_benchmark_premium, type: Money
    end
  end
end
