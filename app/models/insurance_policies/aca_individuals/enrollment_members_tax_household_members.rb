# frozen_string_literal: true

module InsurancePolicies
  module AcaIndividuals
    class EnrollmentMembersTaxHouseholdMembers
      include Mongoid::Document
      include Mongoid::Timestamps

      belongs_to :tax_household_member
      belongs_to :enrollment_member

      field :irs_group_id, type: String
      field :family_assigned_hbx_id, type: String

      embeds_many :insurance_agreements,
                  class_name: '::InsurancePolicies::AcaIndividuals::InsuranceAgreement',
                  cascade_callbacks: true

      accepts_nested_attributes_for :insurance_agreements
    end
  end
end
