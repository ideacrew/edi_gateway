# frozen_string_literal: true

module InsurancePolicies
  module AcaIndividuals
    class TaxHousehold
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :insurance_agreement, class_name: "::InsurancePolicies::AcaIndividuals::InsuranceAgreement"

      field :allocated_aptc, type: Money
      field :max_aptc, type: Money
      field :start_date, type: Date
      field :end_date, type: Date
      field :is_immediate_family, type: Boolean

      embeds_many :tax_household_members, class_name: "::InsurancePolicies::AcaIndividuals::TaxHouseholdMember",
                                          cascade_callbacks: true
    end
  end
end
