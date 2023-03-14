# frozen_string_literal: true

module InsurancePolicies
  module AcaIndividuals
    # Every InsuranceAgreement will have one or more TaxHousehold
    # This class constructs TaxHousehold object
    class TaxHousehold
      include Mongoid::Document
      include Mongoid::Timestamps
      include DomainModels::Domainable

      Money.default_currency = 'USD'

      belongs_to :tax_household_group, class_name: 'InsurancePolicies::AcaIndividuals::TaxHouseholdGroup',
                                       index: true

      # embeds_one :aptc_accumulator
      # embeds_one :contribution_accumulator

      field :hbx_id, type: String
      field :is_eligibility_determined, type: Boolean
      field :allocated_aptc, type: Money
      field :max_aptc, type: Money
      field :yearly_expected_contribution, type: Money
      field :is_aqhp, type: Boolean, default: true

      # field :eligibility_determination_hbx_id, Types::String.optional.meta(omittable: true)

      field :start_on, type: Date
      field :end_on, type: Date

      # indexes
      index({ hbx_id: 1 })
      index({ is_aqhp: 1 })

      has_many :enrollments_tax_households,
               class_name: 'InsurancePolicies::AcaIndividuals::EnrollmentsTaxHouseholds',
               dependent: :destroy

      has_many :tax_household_members, class_name: 'InsurancePolicies::AcaIndividuals::TaxHouseholdMember',
                                       inverse_of: :tax_household, dependent: :destroy
      accepts_nested_attributes_for :tax_household_members

      def enrollments
        Enrollment.in(id: enrollments_tax_households.pluck(:enrollment_id))
      end

      def primary_tax_filer_hbx_id
        primary&.person&.hbx_id || tax_household_members.first.person.hbx_id
      end

      def primary
        thh_members = tax_household_members.where(tax_filer_status: "tax_filer")
        thh_member = if thh_members.count == 1
                       thh_members.first
                     elsif thh_members.count > 1
                       fetch_valid_thh_member(thh_members)
                     end
        thh_member || tax_household_members.where(relation_with_primary: "self").first
      end

      def fetch_valid_thh_member(thh_members)
        thh_members.where(relation_with_primary: 'self').first.presence || thh_members.min_by do |member|
          member.person.hbx_id
        end
      end

      def spouse
        spouse = tax_household_members.where(relation_with_primary: 'spouse').first
        return nil if spouse&.id&.to_s == primary&.id&.to_s

        spouse
      end

      def dependents
        tax_household_members.select do |member|
          member.id.to_s != primary.id.to_s && !%w(spouse self).include?(member.relation_with_primary)
        end
      end
    end
  end
end
