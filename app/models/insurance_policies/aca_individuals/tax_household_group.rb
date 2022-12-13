# frozen_string_literal: true

module InsurancePolicies
  module AcaIndividuals
    # A collection of TaxHouseholds that is generated each time a ACA APTC/CSR eligibility is determined
    class TaxHouseholdGroup
      include Mongoid::Document
      include Mongoid::Timestamps
      include DomainModelHelpers

      has_many :irs_groups, class_name: 'InsurancePolicies::AcaIndividuals::IrsGroup'
      accepts_nested_attributes_for :irs_groups

      has_many :tax_households, class_name: 'InsurancePolicies::AcaIndividuals::TaxHousehold'
      accepts_nested_attributes_for :tax_households

      field :hbx_id, type: String
      field :assistance_year, type: Integer
      field :application_hbx_id, type: String
      field :household_group_benchmark_ehb_premium, type: Money

      field :start_on, type: Date
      field :end_on, type: Date

      index({ hbx_id: 1 }, { unique: true })
      index({ application_hbx_id: 1 })

      def insurance_policies
        InsurancePolicy.in(id: irs_groups.pluck(:irs_groups_id))
      end
    end
  end
end
