# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module InsurancePolicies
  module AcaIndividuals
    # Operation to find tax_household.
    module TaxHouseholds
      class Find
        send(:include, Dry::Monads[:result, :do])

        def call(params)
          validated_params = yield validate(params)
          insurance_policy = yield find_tax_household(validated_params)
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

        def find_tax_household(validated_params)
          scope = search_scope(validated_params)
          thh = ::InsurancePolicies::AcaIndividuals::TaxHousehold.where(scope)

          if thh.present?
            thh_group_hash = thh.as_json(include: [:tax_household_members]).deep_symbolize_keys
            Success(thh_group_hash)
          else
            Failure("Unable to find tax household with ID #{validated_params[:criterion]}.")
          end
        rescue StandardError
          Failure("Unable to find tax household with #{validated_params[:criterion]}.")
        end

        def search_scope(params)
          case params[:scope_name]
          when :by_hbx_id
            { hbx_id: params[:criterion] }
          end
        end
      end
    end
  end
end
