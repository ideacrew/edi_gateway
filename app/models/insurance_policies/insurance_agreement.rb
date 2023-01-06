# frozen_string_literal: true

module InsurancePolicies
  # Every InsurancePolicy will have one Insurance Agreement
  class InsuranceAgreement
    include Mongoid::Document
    include Mongoid::Timestamps
    include DomainModels::Domainable

    field :plan_year, type: String

    belongs_to :contract_holder, class_name: 'People::Person', index: true

    belongs_to :insurance_provider, class_name: 'InsurancePolicies::InsuranceProvider', index: true

    has_many :insurance_policies, class_name: 'InsurancePolicies::AcaIndividuals::InsurancePolicy',
                                  inverse_of: :insurance_agreement
  end
end
