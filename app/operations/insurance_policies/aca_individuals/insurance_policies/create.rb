# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module InsurancePolicies
  module AcaIndividuals
    # Operation to find insurance policy by policy_id.
    module InsurancePolicies
      class Create
        send(:include, Dry::Monads[:result, :do])

        def call(params)
          validated_params = yield validate(params)
          insurance_policy = yield create(validated_params, params[:insurance_product], params[:insurance_agreement],
                                          params[:irs_group])
          Success(insurance_policy)
        end

        private

        def validate(params)
          AcaEntities::InsurancePolicies::AcaIndividuals::Contracts::InsurancePolicyContract.new.call(params)
        end

        def create(validated_params, product, agreement, irs_group)
          attrs = validated_params.to_h
          insurance_policy = ::InsurancePolicies::AcaIndividuals::InsurancePolicy.
            create!(policy_id: attrs[:policy_id], hbx_enrollment_ids: attrs[:hbx_enrollment_ids],
                    start_on: attrs[:start_on],
                    end_on: attrs[:end_on],
                    aasm_state: attrs[:aasm_state],
                    insurance_product_id: product[:id],
                    insurance_agreement_id: agreement[:id],
                    irs_group_id: irs_group[:id],
                    carrier_policy_id: attrs[:carrier_policy_id])

          if insurance_policy.present?
            insurance_policy_hash = insurance_policy.as_json(include: [:insurance_product, :insurance_agreement, :enrollments]).deep_symbolize_keys
            Success(insurance_policy_hash)
          else
            Failure("Unable to create insurance_policy with ID #{validated_params[:policy_id]}.")
          end
        rescue StandardError
          Failure("Unable to create insurance_policy with #{validated_params[:plan_id]}.")
        end
      end
    end
  end
end
