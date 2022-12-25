# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module InsurancePolicies
  module AcaIndividuals
    # Operation to create tax_household group.
    module Enrollments
      class Create
        send(:include, Dry::Monads[:result, :do])

        def call(params)
          validated_params = yield validate(params)
          thh_group = yield create(validated_params, params[:insurance_policy])
          Success(thh_group)
        end

        private

        def validate(params)
          AcaEntities::Contracts::Enrollments::HbxEnrollmentContract.new.call(params)
        end

        def create(validated_params, insurance_policy)
          attrs = validated_params.to_h
          enrollment = ::InsurancePolicies::AcaIndividuals::Enrollment.
            create!(hbx_id: attrs[:hbx_id],
                    aasm_state: attrs[:aasm_state],
                    total_premium_amount: attrs[:total_premium],
                    total_premium_adjustment_amount: attrs[:applied_aptc_amount],
                    effectuated_on: attrs[:effective_on],
                    start_on: attrs[:effective_on],
                    end_on: attrs[:terminated_on],
                    insurance_policy_id: insurance_policy[:id])

          if enrollment.present?
            enrollment_hash = enrollment.to_hash
            Success(enrollment_hash)
          else
            Failure("Unable to create enrollment with ID #{validated_params[:hbx_id]}.")
          end
        rescue StandardError
          Failure("Unable to create enrollment with #{validated_params[:hbx_id]}.")
        end
      end
    end
  end
end
