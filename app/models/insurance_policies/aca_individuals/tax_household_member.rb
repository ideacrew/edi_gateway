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

      #            inverse_of: :tax_household_members

      field :person_hbx_id, type: String
      field :is_subscriber, type: Boolean, default: false
      field :is_tax_filer, type: Boolean
      field :reason, type: String

      def thm_individual
        Person.where(authority_member_id: self.person_hbx_id).first
      end
    end
  end
end
