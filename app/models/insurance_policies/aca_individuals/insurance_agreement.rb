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
      embeds_one :contract_holder, class_name: "::InsurancePolicies::AcaIndividuals::Member", cascade_callbacks: true
      embeds_one :insurance_provider, class_name: "::InsurancePolicies::AcaIndividuals::InsuranceProvider",
                                      cascade_callbacks: true
      embeds_many :tax_households, class_name: "::InsurancePolicies::AcaIndividuals::TaxHousehold", cascade_callbacks: true

      accepts_nested_attributes_for :insurance_provider
      accepts_nested_attributes_for :contract_holder
      accepts_nested_attributes_for :insurance_provider
      accepts_nested_attributes_for :tax_households

      def covered_month_tax_household(calendar_year, calendar_month)
        date = Date.new(calendar_year, calendar_month, 1)
        tax_households.select do |thh|
          end_date = thh.end_date.present? ? thh.end_date : Date.new(calendar_year, 12, 31)
          date.between?(thh.start_date, end_date)
        end.last
      end
    end
  end
end
