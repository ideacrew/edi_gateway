# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module InsurancePolicies
  module AcaIndividuals
    module TaxHouseholdGroups
      # Operation to create tax_household group.
      class Create
        send(:include, Dry::Monads[:result, :do])

        def call(params)
          validated_params = yield validate(params)
          thh_group = yield create(validated_params, params[:irs_group_id])
          Success(thh_group)
        end

        private

        def validate(params)
          AcaEntities::Contracts::Households::TaxHouseholdGroupContract.new.call(params)
        end

        # rubocop:disable Metrics/MethodLength
        def create(validated_params, irs_group_id)
          attrs = validated_params.to_h
          thh_group = ::InsurancePolicies::AcaIndividuals::TaxHouseholdGroup
                      .create!(hbx_id: attrs[:hbx_id],
                               start_on: attrs[:start_on],
                               end_on: attrs[:end_on],
                               assistance_year: attrs[:assistance_year],
                               application_hbx_id: attrs[:application_hbx_id],
                               irs_group_id: irs_group_id)

          if thh_group.present?
            thh_group_hash = thh_group.as_json(include: [:tax_households]).deep_symbolize_keys
            Success(thh_group_hash)
          else
            Failure("Unable to create tax household group with ID #{validated_params[:hbx_id]}.")
          end
        rescue StandardError
          Failure("Unable to create tax household group with #{validated_params[:hbx_id]}.")
        end
        # rubocop:enable Metrics/MethodLength
      end
    end
  end
end
