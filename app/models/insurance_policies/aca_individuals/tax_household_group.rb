# frozen_string_literal: true

module InsurancePolicies
  module AcaIndividuals
    # Every IRS Group will have many tax household groups
    class TaxHouseholdGroup
      include Mongoid::Document
      include Mongoid::Timestamps

      field :hbx_id, type: String
      field :start_on, type: Date
      field :end_on, type: Date
      field :assistance_year, type: Integer
      field :source, type: String
      field :source, type: String

      embeds_many :tax_households, class_name: "::InsurancePolicies::AcaIndividuals::TaxHousehold", cascade_callbacks: true
      embedded_in :irs_group
      # accepts_nested_attributes_for :tax_household_groups

      def covered_month_tax_household(calendar_year, calendar_month)
        tax_household = covered_calendar_year_thh(calendar_year, calendar_month)
        return tax_household if tax_household.present?

        tax_households.detect { |thh| thh.is_immediate_family == true }
      end

      def covered_calendar_year_thh(calendar_year, calendar_month)
        date = Date.new(calendar_year, calendar_month, 1)
        calendar_year_thhs = tax_households.where(start_date: Date.new(calendar_year)..Date.new(calendar_year).end_of_year,
                                                  is_immediate_family: nil)
        calendar_year_thhs.select do |thh|
          end_date = thh.end_date.present? ? thh.end_date : Date.new(calendar_year, 12, 31)
          date.between?(thh.start_date, end_date)
        end.last
      end

    end
  end
end
