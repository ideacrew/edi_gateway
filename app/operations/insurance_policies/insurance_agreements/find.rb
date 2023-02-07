# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module InsurancePolicies
  module InsuranceAgreements
    # Operation to find insurance product by hios_plan_id and year.
    class Find
      send(:include, Dry::Monads[:result, :do])

      def call(params)
        validated_params = yield validate(params)
        insurance_agreement = yield find_insurance_agreement(validated_params)

        Success(insurance_agreement)
      end

      private

      def validate(params)
        return Failure("plan_year should not be blank") if params[:plan_year].blank?
        return Failure("Insurance Provider should not be blank") if params[:insurance_provider_id].blank?
        return Failure("Contract Holder should not be blank") if params[:contract_holder_id].blank?

        Success(params)
      end

      def find_insurance_agreement(validated_params)
        insurance_agreement = ::InsurancePolicies::InsuranceAgreement
                              .where(plan_year: validated_params[:plan_year],
                                     insurance_provider_id: validated_params[:insurance_provider_id],
                                     contract_holder_id: validated_params[:contract_holder_id]).first

        if insurance_agreement.present?
          insurance_agreement_hash = insurance_agreement.as_json(include: [:contract_holder, :insurance_provider,
                                                                           :insurance_policy]).deep_symbolize_keys
          Success(insurance_agreement_hash)
        else
          Failure("Unable to find insurance_agreement with ID #{validated_params[:hios_plan_id]}.")
        end
      rescue StandardError
        Failure("Unable to find insurance_agreement with #{validated_params[:hios_plan_id]}.")
      end
    end
  end
end
