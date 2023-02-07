# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module InsurancePolicies
  module AcaIndividuals
    module EnrolledMembersAndTaxHouseholdMembers
      # Operation to create tax_household group.
      class Create
        send(:include, Dry::Monads[:result, :do])

        def call(params)
          validated_params = yield validate(params)
          thh_group = yield create(validated_params.to_h, params[:enrollment_tax_household], params[:person])
          Success(thh_group)
        end

        private

        # params - cv3 + edi_gateway merge {}
        def validate(params)
          AcaEntities::Contracts::PremiumCredits::TaxHouseholdMemberEnrollmentMemberContract.new.call(params
            .except(:enrollment_tax_household, :person))
        end

        # rubocop:disable Metrics/AbcSize
        def create(params, enrollment_tax_household, person)
          result = ::InsurancePolicies::AcaIndividuals::EnrolledMembersTaxHouseholdMembers
                   .create!(person_hbx_id: params[:family_member_reference][:family_member_hbx_id],
                            age_on_effective_date: params[:age_on_effective_date],
                            relationship_with_primary: params[:relationship_with_primary],
                            date_of_birth: params[:date_of_birth],
                            enrollments_tax_households_id: enrollment_tax_household[:id],
                            person_id: person[:id])

          if result.present?
            result_hash = result.as_json(include: [:enrollments_tax_households]).deep_symbolize_keys
            Success(result_hash)
          else
            Failure("Unable to create enrollment member thh member with ID
#{params[:family_member_reference][:family_member_hbx_id]}.")
          end
        rescue StandardError
          Failure("Unable to create enrollment member thh member with
#{params[:family_member_reference][:family_member_hbx_id]}.")
        end
        # rubocop:enable Metrics/AbcSize
      end
    end
  end
end
