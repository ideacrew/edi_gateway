# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module InsurancePolicies
  module AcaIndividuals
    module EnrolledMembersAndTaxHouseholdMembers
      # Operation to find enrolled_member_tax_household_member.
      class Find
        send(:include, Dry::Monads[:result, :do])

        def call(params)
          validated_params = yield validate(params)
          insurance_policy = yield find_member(validated_params)
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

        def find_member(validated_params)
          scope = search_scope(validated_params)
          result = ::InsurancePolicies::AcaIndividuals::EnrolledMembersTaxHouseholdMembers.where(scope).first

          if result.present?
            result_hash = result.as_json(include: [:enrollments_tax_households]).deep_symbolize_keys
            Success(result_hash)
          else
            Failure("Unable to find tax household group with ID #{validated_params[:scope_name]}.")
          end
        rescue StandardError
          Failure("Unable to find tax household group with #{validated_params[:scope_name]}.")
        end

        def search_scope(params)
          case params[:scope_name]
          when :by_person_hbx_id
            { person_hbx_id: params[:person_hbx_id] }
          end
        end
      end
    end
  end
end
