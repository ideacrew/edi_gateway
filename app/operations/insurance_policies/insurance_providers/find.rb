# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module InsurancePolicies
  module InsuranceProviders
    # Operation to find insurance provider by hios_id.
    class Find
      send(:include, Dry::Monads[:result, :do])

      def call(params)
        validated_params = yield validate(params)
        insurance_provider = yield find_provider(validated_params[:hios_id])

        Success(insurance_provider)
      end

      private

      def validate(params)
        return Failure("Carrier hios id should not be blank") if params[:hios_id].blank?

        Success(params)
      end

      def find_provider(carrier_hios_id)
        insurance_provider = ::InsurancePolicies::InsuranceProvider.where(hios_id: carrier_hios_id).first

        if insurance_provider.present?
          provider_hash = insurance_provider.as_json(include: [:insurance_products]).deep_symbolize_keys
          Success(provider_hash)
        else
          Failure("Unable to find insurance_provider with ID #{carrier_hios_id}.")
        end
      rescue StandardError
        Failure("Unable to find insurance_provider with ID2 #{carrier_hios_id}.")
      end
    end
  end
end
