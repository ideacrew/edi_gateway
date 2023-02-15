# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module InsurancePolicies
  module InsuranceProviders
    # Find or Create a new {InsurancePolicies::InsuranceProduct} record in the database
    class FindOrCreate
      send(:include, Dry::Monads[:result, :do])

      def call(params)
        values = yield validate(params)
        product = yield find_or_create(values)

        Success(product)
      end

      private

      def validate(params)
        return Failure('Unable to find policy') if params[:policy].blank?
        return Failure('Unable to find product_hash') if params[:product_hash].blank?

        Success(params)
      end

      def find_or_create(values)
        carrier = values[:policy].carrier
        params = { hios_id: values[:policy].plan.hios_plan_id.split('ME')[0], title: carrier.name, fein: carrier.fein }
        provider = InsurancePolicies::InsuranceProviders::Find.new.call(params)
        return provider if provider.success?

        params.merge!(insurance_products: [values[:product_hash]])
        InsurancePolicies::InsuranceProviders::Create.new.call(params)
      end
    end
  end
end
