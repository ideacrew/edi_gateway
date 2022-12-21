# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module InsurancePolicies
  module InsuranceProducts
    # Persist a new {InsurancePolicies::InsuranceAgreement} record in the database
    class Create
      send(:include, Dry::Monads[:result, :do])

      # @param [Hash] params the parameters used to create a new Customer
      # @option params [AcaEntities::InsurancePolicies::Contracts::InsuranceProductContract]
      # @return [Dry::Monad::Success] InsuranceProduct record created
      # @return [Dry::Monad::Failure] failed to create InsuranceProduct record

      def call(params)
        values = yield validate(params)
        provider = yield create(values, params[:insurance_provider_hash])

        Success(provider)
      end

      private

      def validate(params)
        AcaEntities::InsurancePolicies::Contracts::InsuranceProductContract.new.call(params)
      end

      def create(values, insurance_provider)
        attrs = values.to_h.merge!(insurance_provider_id: insurance_provider[:id])
        product = ::InsurancePolicies::InsuranceProduct.create!(attrs)
        if product
          product_hash = product.as_json(include: [:insurance_provider]).deep_symbolize_keys
          Success(product_hash)
        else
          Failure("unable to create product")
        end
      end
    end
  end
end

1483705