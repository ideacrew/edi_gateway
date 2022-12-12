# frozen_string_literal: true

module InsurancePolicies
  # A carrier who offers insurance policy products
  class InsuranceProvider
    include Mongoid::Document
    include Mongoid::Timestamps
    include DomainModelHelpers

    has_many :aca_individuals_insurance_agreements,
             class_name: 'InsurancePolicies::AcaIndividuals::InsuranceAgreement',
             inverse_of: :insurance_provider

    embedded_in :enrolled_member, class_name: 'InsurancePolicies::EnrolledMember'

    has_many :insurance_products

    required(:title).value(:string)
    required(:hios_id).filled(:string)

    # required(:organization).filled(AcaEntities::Organizations::Contracts::OrganizationContract.params)
    optional(:insurance_products).array(AcaEntities::InsurancePolicies::Contracts::InsuranceProductContract.params)

    # optional(:insurance_policies).array(
    #   AcaEntities::InsurancePolicies::Contracts::IndividualInsurancePolicyContract.params
    # )
    optional(:description).value(:string)
    optional(:text).value(:string)
  end
end
