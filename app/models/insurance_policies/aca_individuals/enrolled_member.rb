# frozen_string_literal: true

module InsurancePolicies
  # A {Member} who is enrolling for coverage on the SBM
  module AcaIndividuals
    class EnrolledMember
      include Mongoid::Document
      include Mongoid::Timestamps
      include DomainModels::Domainable

      belongs_to :person, class_name: 'People::Person', index: true
      accepts_nested_attributes_for :person

      embeds_one :premium_schedule, class_name: 'InsurancePolicies::PremiumSchedule'
      accepts_nested_attributes_for :premium_schedule

      # Subscriber Association
      embedded_in :aca_individuals_enrollment,
                  class_name: 'InsurancePolicies::AcaIndividuals::Enrollment'

      # Dependnet Association
      embedded_in :aca_individuals_enrollment,
                  class_name: 'InsurancePolicies::AcaIndividuals::Enrollment'

      field :insurer_assigned_id, type: String
      field :encrypted_ssn, type: String
      field :ssn, type: String
      field :dob, type: Date, as: :date_of_birth
      field :gender, type: String
      field :tobacco_use, type: String, default: 'NA'

      # VLP, American Indian
      # embeds_many :aca_individuals_eligibilities

      # Tobacco User
      # embeds_many :aca_individuals_rating_factors

      field :homeless, type: Boolean, default: false

      field :temporarily_out_of_state, type: Boolean, default: false

      # SSN, Age-off, Temporarily Out-Of-State, Homeless
      # embeds_many :aca_individuals_enrollment_exemptions do
      #   ssn_exempt
      #   age_off_exempt
      # end
      field :disabled, type: Boolean, default: false
      field :age_off_exempt, type: Boolean, default: false
      field :relation_with_primary, type: String
    end
  end
end
