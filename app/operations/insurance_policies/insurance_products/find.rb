# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module InsurancePolicies
  module InsuranceProducts
    # Operation to find insurance product by hios_plan_id and year.
    class Find
      send(:include, Dry::Monads[:result, :do])

      def call(params)
        validated_params = yield validate(params)
        insurance_product = yield find_product(validated_params)

        Success(insurance_product)
      end

      private

      def validate(params)
        return Failure("HIOS Plan Id should not be blank") if params[:hios_plan_id].blank?
        return Failure("Plan year should not be blank") if params[:plan_year].blank?

        Success(params)
      end

      def find_product(validated_params)
        insurance_product = ::InsurancePolicies::InsuranceProduct
                            .where(hios_plan_id: validated_params[:hios_plan_id], plan_year: validated_params[:plan_year]).first

        if insurance_product.present?
          product_hash = insurance_product.as_json(include: [:insurance_provider]).deep_symbolize_keys
          Success(product_hash)
        else
          Failure("Unable to find insurance_product with ID #{validated_params[:hios_plan_id]}.")
        end
      rescue StandardError
        Failure("Unable to find insurance_product with #{validated_params[:hios_plan_id]}.")
      end
    end
  end
end
