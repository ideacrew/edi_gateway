# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module InsurancePolicies
  module AcaIndividuals
    module IrsGroups
      # Operation to find  irs_group.
      class Find
        send(:include, Dry::Monads[:result, :do])

        def call(params)
          validated_params = yield validate(params)
          irs_group = yield find_irs_group(validated_params)
          Success(irs_group)
        end

        private

        def validate(params)
          if params.keys.include? :scope_name
            Success(params)
          else
            Failure('params must include :scope_name')
          end
        end

        def find_irs_group(validated_params)
          scope = search_scope(validated_params)
          irs_group = ::InsurancePolicies::AcaIndividuals::IrsGroup.where(scope).first

          if irs_group.present?
            irs_group_hash = irs_group.to_hash
            Success(irs_group_hash)
          else
            Failure("Unable to find IRS group with ID #{validated_params[:criterion]}.")
          end
        rescue StandardError
          Failure("Unable to find IRS household group with #{validated_params[:criterion]}.")
        end

        def search_scope(params)
          case params[:scope_name]
          when :by_irs_group_id
            { irs_group_id: params[:criterion] }
          end
        end
      end
    end
  end
end
