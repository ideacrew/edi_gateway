# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module InsurancePolicies
  module InsuranceProducts
    # Find or Create a new {InsurancePolicies::InsuranceProduct} record in the database
    class FindOrCreate
      send(:include, Dry::Monads[:result, :do])

      def call(params)
        values = yield validate(params)
        provider = yield find_or_create(values)

        Success(provider)
      end

      private

      def validate(params)
        return Failure('Unable to find policy') if params[:policy].blank?
        return Failure('Unable to find provider_hash') if params[:provider_hash].blank?
        return Failure('Unable to find product_hash') if params[:product_hash].blank?

        Success(params)
      end

      def find_or_create(values)
        product = find_product(values)
        return product if product.success?

        product_params = values[:product_hash].merge(insurance_provider_hash: values[:provider_hash])
        InsurancePolicies::InsuranceProducts::Create.new.call(product_params)
      end

      def find_product(values)
        plan = values[:policy].plan
        InsurancePolicies::InsuranceProducts::Find.new.call({ hios_plan_id: plan.hios_plan_id, plan_year: plan.year })
      end
    end
  end
end
