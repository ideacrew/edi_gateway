# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module InsurancePolicies
  module InsuranceAgreements
    # Find or Create a new {InsurancePolicies::InsuranceAgreement} record in the database
    class FindOrCreate
      send(:include, Dry::Monads[:result, :do])

      def call(params)
        values = yield validate(params)
        agreement = yield find_or_create(values)

        Success(agreement)
      end

      private

      def validate(params)
        return Failure('Unable to find contract_holder_hash') if params[:contract_holder_hash].blank?
        return Failure('Unable to find policy') if params[:policy].blank?
        return Failure('Unable to find provider_hash') if params[:provider_hash].blank?
        return Failure('Unable to find product_hash') if params[:product_hash].blank?
        return Failure('Unable to find insurance_policy_hash') if params[:insurance_policy_hash].blank?

        Success(params)
      end

      def find_or_create(values)
        agreement = find_agreement(values)
        return agreement if agreement.success?

        InsurancePolicies::InsuranceAgreements::Create.new.call(
          {
            plan_year: values[:policy].plan.year,
            contract_holder: map_person_to_contract_params(values[:contract_holder_hash]),
            insurance_provider: values[:provider_hash],
            insurance_policy: values[:insurance_policy_hash].merge(insurance_product: values[:product_hash])
          }
        )
      end

      def find_agreement(values)
        InsurancePolicies::InsuranceAgreements::Find.new.call(
          {
            plan_year: values[:policy].plan.year,
            insurance_provider_id: values[:provider_hash][:id],
            contract_holder_id: values[:contract_holder_hash][:id]
          }
        )
      end

      def map_person_to_contract_params(person_hash)
        person_hash.merge!(person_name: person_hash[:name])
        person_hash[:addresses].collect { |address| address[:city] = address[:city_name] }
        person_hash
      end
    end
  end
end
