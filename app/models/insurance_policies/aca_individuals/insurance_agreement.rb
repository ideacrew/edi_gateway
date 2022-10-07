# frozen_string_literal: true

module InsurancePolicies
  module AcaIndividuals
    class InsuranceAgreement
      include Mongoid::Document
      include Mongoid::Timestamps

      field :start_on, type: Date
      field :end_on, type: Date
      field :effectuated_on, type: Date
      field :policy_id, type: String
      field :marketplace_segment_id, type: String
      field :plan_year, type: String

      embedded_in :irs_group, class_name: "::InsurancePolicies::AcaIndividuals::IrsGroup"
      embeds_one :contract_holder, class_name: "::InsurancePolicies::AcaIndividuals::Member"
      embeds_one :insurance_provider, class_name: "::InsurancePolicies::AcaIndividuals::InsuranceProvider"
      embeds_many :tax_households, class_name: "::InsurancePolicies::AcaIndividuals::TaxHousehold"

      accepts_nested_attributes_for :insurance_provider
      accepts_nested_attributes_for :contract_holder
      accepts_nested_attributes_for :insurance_provider
      accepts_nested_attributes_for :tax_households
    end
  end
end