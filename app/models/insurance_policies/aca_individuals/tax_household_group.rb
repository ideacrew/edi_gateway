# frozen_string_literal: true

module InsurancePolicies
  module AcaIndividuals
    # Every IRS Group will have many tax household groups
    class TaxHouseholdGroup
      include Mongoid::Document
      include Mongoid::Timestamps

      field :tax_household_group_hbx_id, type: String
      field :start_on, type: Date
      field :end_on, type: Date
      field :assistance_year, type: Integer
      field :source, type: String
      field :source, type: String

      embeds_many :tax_households, class_name: "::InsurancePolicies::AcaIndividuals::TaxHousehold", cascade_callbacks: true
      embedded_in :irs_group
      # accepts_nested_attributes_for :tax_household_groups
    end
  end
end
