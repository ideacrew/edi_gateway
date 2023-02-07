# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module InsurancePolicies
  module AcaIndividuals
    module IrsGroups
      # Operation to create irs_group.
      class Create
        send(:include, Dry::Monads[:result, :do])

        def call(params)
          validated_params = yield validate(params)
          irs_group = yield create(validated_params)
          Success(irs_group)
        end

        private

        def validate(params)
          return Failure("Unable to find irs group id") if params[:irs_group_id].blank?

          Success(params)
        end

        def create(validated_params)
          attrs = validated_params.to_h
          irs_group = ::InsurancePolicies::AcaIndividuals::IrsGroup.create!(irs_group_id: attrs[:irs_group_id],
                                                                            start_on: attrs[:start_on])

          if irs_group.present?
            irs_group_hash = irs_group.to_hash
            Success(irs_group_hash)
          else
            Failure("Unable to create IRS group with ID #{validated_params[:criterion]}.")
          end
        rescue StandardError
          Failure("Unable to create IRS household group with #{validated_params[:criterion]}.")
        end
      end
    end
  end
end
