# frozen_string_literal: true

module InsurancePolicies
  module AcaIndividuals
    class TaxHousehold
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :insurance_agreement, class_name: "InsurancePolicies::AcaIndividuals::InsuranceAgreement"

      field :allocated_aptc, type: BigDecimal
      field :max_aptc, type: BigDecimal
      field :start_date, type: Date
      field :end_date, type: Date

      embeds_many :tax_household_members, class_name: "InsurancePolicies::AcaIndividuals::TaxHouseholdMember"
    end
  end
end