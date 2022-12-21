# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module InsurancePolicies
  module AcaIndividuals
    # Operation to create tax_household group.
    module TaxHouseholdGroups
      class Create
        send(:include, Dry::Monads[:result, :do])

        def call(params)
          validated_params = yield validate(params)
          thh_group = yield create(validated_params)
          Success(thh_group)
        end

        private

        def validate(params)
          binding.pry
          AcaEntities::Contracts::Households::TaxHouseholdGroupContract.new.call(params)
        end

        def create(validated_params)
          attrs = validated_params.to_h
          thh_group = ::InsurancePolicies::AcaIndividuals::TaxHouseholdGroup.
            create!(hbx_id: attrs[:hbx_id],
                    start_on: attrs[:start_on],
                    end_on: attrs[:end_on],
                    assistance_year: attrs[:assistance_year],
                    application_hbx_id: attrs[:application_hbx_id])

          if thh_group.present?
            thh_group_hash = thh_group.as_json(include: [:tax_households]).deep_symbolize_keys
            Success(thh_group_hash)
          else
            Failure("Unable to create tax household group with ID #{validated_params[:hbx_id]}.")
          end
        rescue StandardError
          Failure("Unable to create tax household group with #{validated_params[:hbx_id]}.")
        end
      end
    end
  end
end
