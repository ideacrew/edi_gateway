# frozen_string_literal: true

module InsurancePolicies
  module AcaIndividuals
    class EnrollmentMembersTaxHouseholdMembers
      include Mongoid::Document
      include Mongoid::Timestamps

      has_many :tax_households
      has_many :enrollments

      belongs_to :enrolled_members
      belongs_to :tax_household_members

      def enrolled_member
        EnrolledMember.in(id: enrollments.enrollment_members.pluck(:enrollment_member_id))
      end

      def tax_household_member
        TaxHouseholdMember.in(id: tax_households.tax_household_members.pluck(:tax_household_member_id))
      end

      field :irs_group_id, type: String
      field :family_assigned_hbx_id, type: String

      embeds_many :insurance_agreements,
                  class_name: '::InsurancePolicies::AcaIndividuals::InsuranceAgreement',
                  cascade_callbacks: true

      accepts_nested_attributes_for :insurance_agreements
    end
  end
end
