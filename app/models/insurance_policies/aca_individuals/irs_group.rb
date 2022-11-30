# frozen_string_literal: true

module InsurancePolicies
  module AcaIndividuals
    class IrsGroup
      include Mongoid::Document
      include Mongoid::Timestamps

      field :irs_group_id, type: String
      field :start_on, type: Date
      field :end_on, type: Date
      field :family_assigned_hbx_id, type: String

      embeds_many :insurance_agreements, class_name: "::InsurancePolicies::AcaIndividuals::InsuranceAgreement",
                                         cascade_callbacks: true
      embeds_many :tax_household_groups, class_name: "::InsurancePolicies::AcaIndividuals::TaxHouseholdGroup",
                  cascade_callbacks: true

      accepts_nested_attributes_for :insurance_agreements
      accepts_nested_attributes_for :tax_household_groups
    end
  end
end
