# frozen_string_literal: true

module InsurancePolicies
  module AcaIndividuals
    class TaxHouseholdGroup
      include Mongoid::Document
      include Mongoid::Timestamps
      include DomainModelHelpers

      # belongs_to :insurance_agreement, class_name: 'InsurancePolicies::AcaIndividuals::InsuranceAgreement'
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
    end
  end
end
