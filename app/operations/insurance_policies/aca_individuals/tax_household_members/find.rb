# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module InsurancePolicies
  module AcaIndividuals
    module TaxHouseholdMembers
      # Operation to find tax_household member.
      class Find
        send(:include, Dry::Monads[:result, :do])

        def call(params)
          validated_params = yield validate(params)
          insurance_policy = yield find_tax_household_member(validated_params)
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

        def find_tax_household_member(validated_params)
          scope = search_scope(validated_params)
          thh_member = ::InsurancePolicies::AcaIndividuals::TaxHouseholdMember.where(scope).first

          if thh_member.present?
            thh_member_hash = thh_member.as_json(include: [:tax_household]).deep_symbolize_keys
            Success(thh_member_hash)
          else
            Failure("Unable to find tax household member with ID #{validated_params[:person_hbx_id]}.")
          end
        rescue StandardError
          Failure("Unable to find tax household member with #{validated_params[:person_hbx_id]}.")
        end

        def search_scope(params)
          case params[:scope_name]
          when :by_person_hbx_id_tax_household_id
            { person_hbx_id: params[:person_hbx_id], tax_household_id: params[:tax_household_id] }
          end
        end
      end
    end
  end
end
