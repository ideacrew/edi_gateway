# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module InsurancePolicies
  module AcaIndividuals
    # Operation to create tax_household group.
    module EnrollmentsAndTaxHouseholds
      class Create
        send(:include, Dry::Monads[:result, :do])

        def call(params)
          validated_params = yield validate(params)
          thh_group = yield create(validated_params.to_h, params[:tax_household], params[:enrollment])
          Success(thh_group)
        end

        private

        def validate(params)
          AcaEntities::Contracts::PremiumCredits::TaxHouseholdEnrollmentContract.new.call(params.except(:tax_household,
                                                                                                        :enrollment))
        end

        def create(params, tax_household_hash, enrollment_hash)
          enrollment_thh = ::InsurancePolicies::AcaIndividuals::EnrollmentsTaxHouseholds.
            create!(applied_aptc: params[:applied_aptc],
                    available_max_aptc: params[:available_max_aptc],
                    enrollment_id: enrollment_hash[:id],
                    tax_household_id: tax_household_hash[:id])

          if enrollment_thh.present?
            thh_group_hash = enrollment_thh.as_json(include: [:enrolled_members_tax_household_members]).deep_symbolize_keys
            Success(thh_group_hash)
          else
            Failure("Unable to create enrollment tax household with ID #{enrollment_hash[:id]}.")
          end
        rescue StandardError
          Failure("Unable to create enrollment tax household with #{enrollment_hash[:id]}.")
        end
      end
    end
  end
end
