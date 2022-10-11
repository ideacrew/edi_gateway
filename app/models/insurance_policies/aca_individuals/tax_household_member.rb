# frozen_string_literal: true

module InsurancePolicies
  module AcaIndividuals
    class TaxHouseholdMember
      include Mongoid::Document
      include Mongoid::Timestamps

      field :is_ia_eligible, type: Boolean, default: false
      field :is_medicaid_chip_eligible, type: Boolean, default: false
      field :is_totally_ineligible, type: Boolean, default: false
      field :is_uqhp_eligible, type: Boolean, default: false
      field :is_subscriber, type: Boolean, default: false
      field :is_tax_filer, type: Boolean
      field :reason, type: String
      field :is_non_magi_medicaid_eligible, type: Boolean, default: false
      field :magi_as_percentage_of_fpl, type: Float, default: 0.0
      field :magi_medicaid_type, type: String
      field :magi_medicaid_category, type: String
      field :magi_medicaid_monthly_household_income, type: Money, default: 0.00
      field :magi_medicaid_monthly_income_limit, type: Money, default: 0.00
      field :medicaid_household_size, type: Integer
      field :is_without_assistance, type: Boolean, default: false
      field :csr, type: Integer, default: 0
      field :person_hbx_id, type: String
      field :tax_filer_status, type: String
      field :slcsp_benchmark_premium, type: Money
      field :relation_with_primary, type: String

      embedded_in :tax_household, class_name: "::InsurancePolicies::AcaIndividuals::TaxHousehold"

      def thm_individual
        Person.where(authority_member_id: self.person_hbx_id).first
      end
    end
  end
end
