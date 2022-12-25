# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module InsurancePolicies
  module AcaIndividuals
    # Operation to create tax_household group.
    module TaxHouseholds
      class Create
        send(:include, Dry::Monads[:result, :do])

        def call(params)
          validated_params = yield validate(params)
          thh_group = yield create(validated_params, params[:tax_household_group])
          Success(thh_group)
        end

        private

        def validate(params)
          AcaEntities::Contracts::Households::TaxHouseholdContract.new.call(params)
        end

        def create(validated_params, tax_household_group)
          attrs = validated_params.to_h
          thh = ::InsurancePolicies::AcaIndividuals::TaxHousehold.
            create!(hbx_id: attrs[:hbx_id],
                    allocated_aptc: attrs[:allocated_aptc],
                    max_aptc: attrs[:max_aptc],
                    is_eligibility_determined: attrs[:is_eligibility_determined],
                    start_on: attrs[:start_date],
                    end_on: attrs[:end_date],
                    yearly_expected_contribution: attrs[:yearly_expected_contribution],
                    tax_household_group_id: tax_household_group[:id])

          if thh.present?
            thh_hash = thh.as_json(include: [:tax_household_members]).deep_symbolize_keys
            Success(thh_hash)
          else
            Failure("Unable to create tax_household with ID #{validated_params[:hbx_id]}.")
          end
        rescue StandardError
          Failure("Unable to create tax household with #{validated_params[:hbx_id]}.")
        end
      end
    end
  end
end
