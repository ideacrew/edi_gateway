# frozen_string_literal: true

module InsurancePolicies
  # Every InsurancePolicy will have one Insurance Agreement
  class ContractHolder
    include Mongoid::Document
    include Mongoid::Timestamps
    include DomainModels::Domainable

    # Account ID is reference to Account model stored in external RDBMS and is
    # managed by application (rather than Mongoid)
    field :account_id, type: String

    index({ account_id: 1 }, { unique: true })

    # Return the UserFees::Account for this InsuranceAgreement
    def account
      Account.find(self.account_id)
    end
  end
end
