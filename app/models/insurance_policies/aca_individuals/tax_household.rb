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

      def primary
        if is_immediate_family == true
          tax_household_members.where(relation_with_primary: "self").first
        else
          tax_household_members.where(tax_filer_status: "tax_filer").first ||
            tax_household_members.where(relation_with_primary: "self").first
        end
      end

      def spouse
        tax_household_members.where(relation_with_primary: 'spouse').first
      end

      def dependents
        tax_household_members.select do |member|
          member.id.to_s != primary.id.to_s && !%w(spouse self).include?(member.relation_with_primary)
        end
      end
    end
  end
end
