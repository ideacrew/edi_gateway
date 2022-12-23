# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module InsurancePolicies
  module AcaIndividuals
    # Operation to create tax_household group.
    module EnrollmentsTaxHouseholds
      class Create
        send(:include, Dry::Monads[:result, :do])

        def call(params)
          validated_params = yield validate(params)
          thh_group = yield create(validated_params.to_h)
          Success(thh_group)
        end

        private

        def validate(params)
          AcaEntities::Contracts::PremiumCredits::TaxHouseholdEnrollmentContract.new.call({})
          #params {{}, }
        end

        def create(params)
          enrollment_thh = ::InsurancePolicies::AcaIndividuals::EnrollmentsTaxHouseholds.create!(applied_aptc: params[:applied_aptc],
                    available_max_aptc: attrs[:available_max_aptc],
                    enrollment_id: attrs[:enrollment_id],
                    tax_household_id: attrs[:tax_household_id])

          if enrollment_thh.present?
            ::InsurancePolicies::AcaIndividuals::EnrolledMembersTaxHouseholdMembers.create!()
            member.create()
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
