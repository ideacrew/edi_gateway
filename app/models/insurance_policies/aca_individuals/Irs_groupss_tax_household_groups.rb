# frozen_string_literal: true

module InsurancePolicies
  module AcaIndividuals
    class TaxHouseholdGroup
      include Mongoid::Document
      include Mongoid::Timestamps

      # belongs_to :insurance_agreement, class_name: '::InsurancePolicies::AcaIndividuals::InsuranceAgreement'
      has_many :tax_households,
               class_name: '::InsurancePolicies::AcaIndividuals::TaxHouseholdGroup',
               cascade_callbacks: true

      field :allocated_aptc, type: Money
      field :max_aptc, type: Money
      field :is_immediate_family, type: Boolean
    end
  end
end
