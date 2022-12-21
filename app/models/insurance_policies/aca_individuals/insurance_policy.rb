# frozen_string_literal: true

module InsurancePolicies
  module AcaIndividuals
    # An instance of continuous coverage under a single insurance product
    class InsurancePolicy
      include Mongoid::Document
      include Mongoid::Timestamps
      include DomainModels::Domainable

      has_many :enrollments, class_name: 'InsurancePolicies::AcaIndividuals::Enrollment'

      accepts_nested_attributes_for :enrollments

      belongs_to :insurance_product, class_name: 'InsurancePolicies::InsuranceProduct'

      belongs_to :insurance_agreement, class_name: 'InsurancePolicies::InsuranceAgreement',
                 inverse_of: :insurance_policies

      belongs_to :irs_group, class_name: 'InsurancePolicies::InsuranceAgreement', optional: true

      # TODO: NEED confirmation
      # belongs_to :plan_years_products, class_name: 'InsurancePolicies::AcaIndividuals::PlanYearsProducts'

      field :policy_id, type: String
      field :insurer_policy_id, type: String
      field :hbx_enrollment_ids, type: Array
      field :marketplace_segment_id, type: String
      field :start_on, type: Date
      field :end_on, type: Date
    end
  end
end
