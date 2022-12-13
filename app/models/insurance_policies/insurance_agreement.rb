# frozen_string_literal: true

module InsurancePolicies
  # Every InsurancePolicy will have one Insurance Agreement
  class InsuranceAgreement
    include Mongoid::Document
    include Mongoid::Timestamps

    # Account ID is reference to Account model stored in external RDBMS and is
    # managed by application (rather than Mongoid)
    field :account_id, type: String

    field :plan_year, type: String

    belongs_to :contract_holder, class_name: "People::Person"

    belongs_to :insurance_provider, class_name: "InsurancePolicies::InsuranceProvider"

    has_one :insurance_policy, class_name: "InsurancePolicies::AcaIndividuals::InsurancePolicy"

    # Return the UserFees::Account for this InsuranceAgreement
    def account
      Account.find(self.account_id)
    end

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