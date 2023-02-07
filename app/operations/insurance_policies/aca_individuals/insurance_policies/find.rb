# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module InsurancePolicies
  module AcaIndividuals
    module InsurancePolicies
      # Operation to find insurance policy by policy_id.
      class Find
        send(:include, Dry::Monads[:result, :do])

        def call(params)
          validated_params = yield validate(params)
          insurance_policy = yield find_insurance_policy(validated_params)
          Success(insurance_policy)
        end

        private

        def validate(params)
          return Failure("policy_id should not be blank") if params[:policy_id].blank?

          Success(params)
        end

        def find_insurance_policy(validated_params)
          insurance_policy = ::InsurancePolicies::AcaIndividuals::InsurancePolicy
                             .where(policy_id: validated_params[:policy_id]).first

          if insurance_policy.present?
            insurance_policy_hash = insurance_policy.as_json(include: [:insurance_product, :insurance_agreement,
                                                                       :enrollments]).deep_symbolize_keys
            Success(insurance_policy_hash)
          else
            Failure("Unable to find insurance_policy with ID #{validated_params[:policy_id]}.")
          end
        rescue StandardError
          Failure("Unable to find insurance_policy with #{validated_params[:policy_id]}.")
        end
      end
    end
  end
end
