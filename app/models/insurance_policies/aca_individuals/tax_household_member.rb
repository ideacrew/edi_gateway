# frozen_string_literal: true

module InsurancePolicies
  module AcaIndividuals
    # Every TaxHousehold will have one or more TaxHouseholdMembers
    # This class constructs TaxHouseholdMember object
    class TaxHouseholdMember
      include Mongoid::Document
      include Mongoid::Timestamps
      include DomainModelHelpers

      belongs_to :tax_household, class_name: 'InsurancePolicies::AcaIndividuals::TaxHousehold'

      field :person_hbx_id, type: String
      field :is_subscriber, type: Boolean, default: false
      field :is_tax_filer, type: Boolean
      field :financial_assistance_applicant, type: Boolean, default: true
      field :reason, type: String
    end
  end
end
