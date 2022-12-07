# frozen_string_literal: true

module InsurancePolicies
  module AcaIndividuals
    # Every InsurancePolicy will have one Insurance Agreement
    class InsuranceAgreement
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :irs_group, class_name: '::InsurancePolicies::AcaIndividuals::IrsGroup'

      field :effectuated_on, type: Date
      field :policy_id, type: String
      field :marketplace_segment_id, type: String
      field :plan_year, type: String

      embeds_one :contract_holder, class_name: '::InsurancePolicies::AcaIndividuals::Member', cascade_callbacks: true
      accepts_nested_attributes_for :contract_holder

      embeds_one :insurance_provider,
                 class_name: '::InsurancePolicies::AcaIndividuals::InsuranceProvider',
                 cascade_callbacks: true
      accepts_nested_attributes_for :insurance_provider

      embeds_one :insurance_ploicies, class_name: '::InsurancePolicies::AcaIndividuals::Member', cascade_callbacks: true

      embeds_many :tax_households,
                  class_name: '::InsurancePolicies::AcaIndividuals::TaxHousehold',
                  cascade_callbacks: true
      accepts_nested_attributes_for :tax_households

      def covered_month_tax_household(calendar_year, calendar_month)
        tax_household = covered_calendar_year_thh(calendar_year, calendar_month)
        return tax_household if tax_household.present?

        tax_households.detect { |thh| thh.is_immediate_family == true }
      end

      def covered_calendar_year_thh(calendar_year, calendar_month)
        date = Date.new(calendar_year, calendar_month, 1)
        calendar_year_thhs =
          tax_households.where(
            start_date: Date.new(calendar_year)..Date.new(calendar_year).end_of_year,
            is_immediate_family: nil
          )
        calendar_year_thhs.select do |thh|
          end_date = thh.end_date.present? ? thh.end_date : Date.new(calendar_year, 12, 31)
          date.between?(thh.start_date, end_date)
        end.last
      end

      def uqhp_tax_household
        tax_households.detect { |thh| thh.is_immediate_family == true }
      end
    end
  end
end
