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
        uqhp_household = tax_households.any?{ |thh| thh.is_immediate_family == true }
        return tax_households.last if uqhp_household

        date = Date.new(calendar_year, calendar_month, 1)
        calendar_year_thhs = tax_households.where(start_date: Date.new(calendar_year)..Date.new(calendar_year).end_of_year)
        tax_household = calendar_year_thhs.select do |thh|
          end_date = thh.end_date.present? ? thh.end_date : Date.new(calendar_year, 12, 31)
          date.between?(thh.start_date, end_date)
        end.last

        return tax_household if tax_household.present?

        fetch_primary_person_tax_household || tax_households.last
      end

      def fetch_primary_person_tax_household
        tax_households.select do |thh|
          thh.tax_household_members.any? {|member| member.relation_with_primary == "self"}
        end.last
      end
    end
  end
end
