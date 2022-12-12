# frozen_string_literal: true

module InsurancePolicies
  module AcaIndividuals
    # A Person known to SBM but not necessarily enrolling for coverage (e.g. # Responsible Party

    class Member
      include Mongoid::Document
      include Mongoid::Timestamps

      belongs_to :aca_individuals_insurance_agreement,
                 class_name: 'InsurancePolicies::AcaIndividuals::InsuranceAgreement',
                 inverse_of: :contract_holder

      belongs_to :enrolled_member, class_name: 'InsurancePolicies::AcaIndividuals::EnrolledMember'

      field :member_id, type: String
      field :coverage_applicant, type: Boolean, default: true

      embeds_one :person, class_name: 'People::Person', cascade_callbacks: true
      accepts_nested_attributes_for :person

      embeds_many :former_genders, class_name: 'PersonGender', cascade_callbacks: true
      accepts_nested_attributes_for :gender_type

      embeds_many :eligibilities
      embeds_many :sbm_roles
    end
  end
end
