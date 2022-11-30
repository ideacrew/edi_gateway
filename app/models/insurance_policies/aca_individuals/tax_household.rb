# frozen_string_literal: true

module InsurancePolicies
  module AcaIndividuals
    # Every InsuranceAgreement will have one or more TaxHousehold
    # This class constructs TaxHousehold object
    class TaxHousehold
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :insurance_agreement, class_name: "::InsurancePolicies::AcaIndividuals::InsuranceAgreement"

      field :tax_household_hbx_id, type: String
      field :allocated_aptc, type: Money
      field :max_aptc, type: Money
      field :start_date, type: Date
      field :end_date, type: Date
      field :is_immediate_family, type: Boolean

      embedded_in :tax_household_group, class_name: "::InsurancePolicies::AcaIndividuals::TaxHouseholdGroup"
      embeds_many :tax_household_members, class_name: "::InsurancePolicies::AcaIndividuals::TaxHouseholdMember",
                                          cascade_callbacks: true

      def primary
        primary_thh = tax_household_members.where(relation_with_primary: "self").first
        if is_immediate_family == true
          primary_thh
        else
          tax_household_members.where(tax_filer_status: "tax_filer").first || primary_thh
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
