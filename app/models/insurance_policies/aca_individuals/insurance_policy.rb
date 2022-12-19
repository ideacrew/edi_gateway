# frozen_string_literal: true

module InsurancePolicies
  module AcaIndividuals
    # An instance of continuous coverage under a single insurance product
    class InsurancePolicy
      include Mongoid::Document
      include Mongoid::Timestamps
      include DomainModels::Domainable

      has_many :irs_groups, class_name: 'InsurancePolicies::AcaIndividuals::IrsGroup'

      # accepts_nested_attributes_for :irs_groups

      has_many :enrollments, class_name: 'InsurancePolicies::AcaIndividuals::Enrollment'

      # accepts_nested_attributes_for :enrollments

      belongs_to :insurance_product, class_name: 'InsurancePolicies::InsuranceProduct'

      belongs_to :insurance_agreement, class_name: 'InsurancePolicies::InsuranceAgreement'

      # TODO: NEED confirmation
      # belongs_to :plan_years_products, class_name: 'InsurancePolicies::AcaIndividuals::PlanYearsProducts'

      field :policy_id, type: String
      field :insurer_policy_id, type: String
      field :marketplace_segment_id, type: String
      field :start_on, type: Date
      field :end_on, type: Date
    end
  end
end
