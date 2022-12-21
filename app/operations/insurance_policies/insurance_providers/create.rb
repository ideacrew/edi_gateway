# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module InsurancePolicies
  module InsuranceProviders
    # Persist a new {InsurancePolicies::InsuranceAgreement} record in the database
    class Create
      send(:include, Dry::Monads[:result, :do])

      # @param [Hash] params the parameters used to create a new Customer
      # @option params [AcaEntities::Ledger::Customer] :customer required
      # @return [Dry::Monad::Success] Customer record created
      # @return [Dry::Monad::Failure] failed to create Customer record

      # params: {title: , hios_id: , fein: }
      def call(params)
        values = yield validate(params)
        provider = yield create(values)

        Success(provider)
      end

      private

      def validate(params)
        AcaEntities::InsurancePolicies::Contracts::InsuranceProviderContract.new.call(params)
      end

      def create(values)
        attrs = values.to_h.except(:insurance_products)
        provider = ::InsurancePolicies::InsuranceProvider.create!(attrs)

        if provider.present?
          provider_hash = provider.as_json(include: [:insurance_products]).deep_symbolize_keys
          Success(provider_hash)
        else
          Failure("Unable to create provider")
        end
      end
    end
  end
end
