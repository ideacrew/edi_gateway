# frozen_string_literal: true

module InsurancePolicies
  # A {Member} who is enrolling for coverage on the SBM
  class EnrolledMember
    include Mongoid::Document
    include Mongoid::Timestamps

    embeds_one :member, class_name: 'InsurancePolicies::Member'
    accepts_nested_attributes_for :member

    embeds_one :premium_amount, class_name: 'InsurancePolicies::PremiumAmount'

    embedded_in :aca_individuals_enrollment,
                as: :subscriber_member,
                class_name: 'InsurancePolicy::AcaIndividuals::Enrollment',
                inverse_of: :subscriber

    embedded_in :aca_individuals_enrollment,
                as: :dependent_member,
                class_name: 'InsurancePolicy::AcaIndividuals::Enrollment',
                inverse_of: :dependents

    field :account_id, type: String
    field :hbx_id, type: String
    field :insurer_assigned_id, type: String
    field :insurer_assigned_subscriber_id, type: String
    field :encrypted_ssn, type: String
    field :dob, type: Date, as: :date_of_birth
    field :gender, type: String
    field :benchmark_ehb_premium_amount, type: Money
    field :coverate_applicant, type: Boolean, default: true

    field :disabled, type: Boolean, default: false
    field :age_off_exempt, type: Boolean, default: false
    field :homeless, type: Boolean, default: false

    field :temporarily_out_of_state, type: Boolean, default: false

    # embeds_many :exemptions do
    #   ssn_exempt
    #   age_off_exempt
    # end
  end
end
