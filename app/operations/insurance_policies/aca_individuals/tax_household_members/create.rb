# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module InsurancePolicies
  module AcaIndividuals
    # Operation to find tax_household.
    module TaxHouseholdMembers
      class Create
        send(:include, Dry::Monads[:result, :do])

        def call(params)
          validated_params = yield validate(params)
          insurance_policy = yield create(validated_params, params[:tax_household], params[:person])
          Success(insurance_policy)
        end

        private

        def validate(params)
          AcaEntities::Contracts::Households::TaxHouseholdMemberContract.new.call(params)
        end

        def create(validated_params, tax_household, person)
          attrs = validated_params.to_h
          thh_member = ::InsurancePolicies::AcaIndividuals::TaxHouseholdMember.
            create!(tax_household_id: tax_household[:id],
                    relation_with_primary: attrs[:family_member_reference][:relation_with_primary],
                    is_ia_eligible: attrs[:product_eligibility_determination][:is_ia_eligible],
                    is_medicaid_chip_eligible: attrs[:product_eligibility_determination][:is_medicaid_chip_eligible],
                    is_non_magi_medicaid_eligible: attrs[:product_eligibility_determination][:is_non_magi_medicaid_eligible],
                    is_totally_ineligible: attrs[:product_eligibility_determination][:is_totally_ineligible],
                    is_without_assistance: attrs[:product_eligibility_determination][:is_without_assistance],
                    is_subscriber: attrs[:is_subscriber],
                    tax_filer_status: attrs[:tax_filer_status],
                    person_id: person[:id])

          if thh_member.present?
            thh_member_hash = thh_member.as_json(include: [:tax_household]).deep_symbolize_keys
            Success(thh_member_hash)
          else
            Failure("Unable to find tax household member with ID #{validated_params[:person_id]}.")
          end
        rescue StandardError
          Failure("Unable to find tax household member with #{validated_params[:person_id]}.")
        end
      end
    end
  end
end
