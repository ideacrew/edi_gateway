# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module InsurancePolicies
  module InsuranceAgreements
    # Persist a new {InsurancePolicies::InsuranceAgreement} record in the database
    class Create
      send(:include, Dry::Monads[:result, :do])

      # @param [Hash] params the parameters used to create a new Customer
      # @option params [ AcaEntities::InsurancePolicies::InsuranceAgreement] required
      # @return [Dry::Monad::Success] agreement record created
      # @return [Dry::Monad::Failure] failed to create agreement record
      #params: { plan_year: plan_year, insurance_provider: {insurance_provider_hash},
      # contract_holder: {contract_holder_hash} }
      def call(params)
        values = yield validate(params)
        customer = yield create(values)

        Success(customer)
      end

      private

      def validate(params)
        AcaEntities::InsurancePolicies::AcaIndividuals::Contracts::InsuranceAgreementContract.new.call(params)
      end

      def create(values)
        attrs = values.to_h
        agreement = ::InsurancePolicies::InsuranceAgreement.create!(plan_year: attrs[:plan_year],
                                                                    contract_holder_id: attrs[:contract_holder][:id],
                                                                    insurance_provider_id: attrs[:insurance_provider][:id])

        if agreement.present?
          agreement_hash = agreement.as_json(include: [:contract_holder, :insurance_provider]).deep_symbolize_keys
          Success(agreement_hash)
        else
          Failure("Unable to create insurance_agreement.")
        end
      end
    end
  end
end


