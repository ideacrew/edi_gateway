# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module InsurancePolicies
  module AcaIndividuals
    module EnrolledMembersTaxHouseholdMembers
      # Operation to create tax_household group.
      class Create
        send(:include, Dry::Monads[:result, :do])

        def call(params)
          validated_params = yield validate(params)
          thh_group = yield create(validated_params.to_h)
          Success(thh_group)
        end

        private

        # params - cv3 + edi_gateway merge {}
        def validate(params)
          AcaEntities::Contracts::PremiumCredits::TaxHouseholdMemberEnrollmentMemberContract.new.call(params)
        end

        def create(params)
          result = ::InsurancePolicies::AcaIndividuals::EnrolledMembersTaxHouseholdMembers
                   .create!(person_hbx_id: params[:person_hbx_id],
                            age_on_effective_date: params[:age_on_effective_date],
                            relationship_with_primary: params[:relationship_with_primary],
                            date_of_birth: params[:date_of_birth],
                            enrollments_tax_households_id: params[:enrollments_tax_households_id],
                            person_id: params[:person_id])

          if result.present?
            result_hash = result.deep_symbolize_keys
            Success(result_hash)
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
