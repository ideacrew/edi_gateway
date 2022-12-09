# frozen_string_literal: true

module InsurancePolicies
  module AcaIndividuals
    class InsurancePolicy
      include Mongoid::Document
      include Mongoid::Timestamps
      include DomainModelHelpers

      has_many :irs_groups, class_name: 'InsurancePolicies::AcaIndividuals::IrsGroup'
      accepts_nested_attributes_for :irs_groups

      belongs_to :insurance_product, 'InsurancePolicies::InsuranceProduct'

      has_many :enrollments, class_name: 'InsurancePolicies::AcaIndividuals::Enrollment'
      accepts_nested_attributes_for :enrollments

      field :policy_id, type: String
      field :insurer_policy_id, type: String
      field :marketplace_segment_id, type: String
      field :start_on, type: Date
      field :end_on, type: Date

      def tax_household_groups
        TaxHouseholdGroup.in(id: irs_groups.pluck(:irs_groups_id))
      end
    end
  end
end
