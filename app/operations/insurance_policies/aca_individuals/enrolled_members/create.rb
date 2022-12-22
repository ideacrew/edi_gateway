# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module InsurancePolicies
  module AcaIndividuals
    # Operation to create tax_household group.
    module EnrolledMembers
      class Create
        send(:include, Dry::Monads[:result, :do])

        def call(params)
          validated_params = yield validate(params)
          @type = params[:type]
          thh_group = yield create(validated_params, params[:person_hash], params[:enrollment_hash],
                                   params[:glue_enrollee])
          Success(thh_group)
        end

        private

        def validate(params)
          AcaEntities::Contracts::Enrollments::HbxEnrollmentMemberContract.new.call(params)
        end

        def find_enrollment(enrollment_hash)
          ::InsurancePolicies::AcaIndividuals::Enrollment.where(hbx_id: enrollment_hash[:hbx_id]).first
        end

        def create(validated_params, person_hash, enrollment_hash, glue_enrollee)
          enrollment = find_enrollment(enrollment_hash)
          case @type
          when "subscriber"
            enrollment.subscriber = ::InsurancePolicies::AcaIndividuals::EnrolledMember.
              new(ssn: glue_enrollee.person.authority_member.ssn,
                  dob: glue_enrollee.person.authority_member.dob,
                  gender: glue_enrollee.person.authority_member.gender,
                  person_id: person_hash[:id],
                  premium_schedule: { premium_amount: glue_enrollee.pre_amt })
            enrollment.save!
          when "dependent"
            enrollment.dependents << ::InsurancePolicies::AcaIndividuals::EnrolledMember.
              new(ssn: glue_enrollee.person.authority_member.ssn,
                  dob: glue_enrollee.person.authority_member.dob,
                  gender: glue_enrollee.person.authority_member.gender,
                  person_id: person_hash[:id],
                  premium_schedule: {premium_amount: glue_enrollee.pre_amt})
          end
          if enrollment.present?
            enrollment_hash = enrollment.to_hash
            Success(enrollment_hash)
          else
            Failure("Unable to create enrollment with ID #{validated_params[:hbx_id]}.")
          end
        rescue StandardError
          Failure("Unable to create enrollment with #{validated_params[:hbx_id]}.")
        end
      end
    end
  end
end
