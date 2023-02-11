# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'bigdecimal'
require 'aca_entities/functions/age_on'

module Tax1095a
  module Transformers
    module InsurancePolicies
      # Family params to be transformed.
      class Cv3Family
        include EventSource::Command
        include Dry::Monads[:result, :do]

        TAX_FORM_TYPES = %w[IVL_TAX Corrected_IVL_TAX IVL_VTA IVL_CAP].freeze

        # params {tax_year: ,tax_form_type:, irs_group_id: }
        def call(params)
          values = yield validate(params)
          irs_group = yield fetch_irs_group(values)
          cv3_payload = yield construct_cv3_family(values, irs_group)
          valid_cv3_payload = yield validate_payload(cv3_payload)
          entity_cv3_payload = yield initialize_entity(valid_cv3_payload)

          Success(entity_cv3_payload)
        end

        private

        def validate(params)
          tax_form_type = params[:tax_form_type]
          tax_year = params[:tax_year]
          irs_group_id = params[:irs_group_id]
          return Failure('Valid tax form type is not present') unless TAX_FORM_TYPES.include?(tax_form_type)
          return Failure('tax_year is not present') unless tax_year.present?
          return Failure('irs_group_id is not present') unless irs_group_id.present?

          Success(params)
        end

        def fetch_irs_group(values)
          result = ::InsurancePolicies::AcaIndividuals::IrsGroup.where(irs_group_id: values[:irs_group_id])
          return Failure("Unable to fetch IRS group for irs_group_id: #{values[:irs_group_id]}") unless result.present?

          Success(result.first)
        end

        # , insurance_agreements, values)
        def construct_cv3_family(values, irs_group)
          params = values.slice(:tax_form_type, :tax_year).merge(irs_group: irs_group)

          InsurancePolicies::AcaIndividuals::InsurancePolicies::ConstructCvFamilyPayload.new.call(params)
        end

        def validate_payload(cv3_payload)
          result = AcaEntities::Contracts::Families::FamilyContract.new.call(cv3_payload)
          result.success? ? Success(result) : Failure("Payload is invalid due to #{result.errors.to_h}")
        end

        def initialize_entity(cv3_payload)
          result =
            Try() do
              entity_cv3_payload = AcaEntities::Families::Family.new(cv3_payload.to_h)
              JSON.parse(entity_cv3_payload.to_hash.to_json)
            end

          result.or { |e| Failure(e) }
        end
      end
    end
  end
end
