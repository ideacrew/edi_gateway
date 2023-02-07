# frozen_string_literal: true

module InsurancePolicies
  # A Person known to SBM but not necessarily enrolling for coverage (e.g. # Responsible Party
  class PremiumSchedule
    include Mongoid::Document
    include Mongoid::Timestamps
    include DomainModels::Domainable

    embedded_in :enrolled_member, class_name: 'InsurancePolicies::AcaIndividuals::EnrolledMember'

    field :premium_amount, type: Money
    field :benchmark_ehb_premium_amount, type: Money
    field :next_due_on, type: Date
    field :non_tobacco_use_premium, type: Money

    # embeds_many :premium_adjustments, class_name: 'InsurancePolicies::PremiumAdjustment'
  end
end
