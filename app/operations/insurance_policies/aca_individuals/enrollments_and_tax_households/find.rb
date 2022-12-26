# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module InsurancePolicies
  module AcaIndividuals
    module EnrollmentsAndTaxHouseholds
      # Operation to find enrollment_tax_household group.
      class Find
        send(:include, Dry::Monads[:result, :do])

        def call(params)
          validated_params = yield validate(params)
          insurance_policy = yield find_enrollment_thh(validated_params)
          Success(insurance_policy)
        end

        private

        def validate(params)
          if params.keys.include? :scope_name
            Success(params)
          else
            Failure('params must include :scope_name')
          end
        end

        def find_enrollment_thh(validated_params)
          scope = search_scope(validated_params)
          enrollment_thh = ::InsurancePolicies::AcaIndividuals::EnrollmentsTaxHouseholds.where(scope).first

          if enrollment_thh.present?
            enrollment_thh_hash = enrollment_thh.as_json(include: [:enrolled_members_tax_household_members]).deep_symbolize_keys
            Success(enrollment_thh_hash)
          else
            Failure("Unable to find enrollment tax household with ID #{validated_params[:enrollment_id]}.")
          end
        rescue StandardError
          Failure("Unable to find enrollment tax household with #{validated_params[:enrollment_id]}.")
        end

        def search_scope(params)
          case params[:scope_name]
          when :by_enrollment_id
            { enrollment_id: params[:enrollment_id] }
          when :by_enrollment_id_tax_household_id
            { enrollment_id: params[:enrollment_id], tax_household_id: params[:tax_household_id] }
          end
        end
      end
    end
  end
end
