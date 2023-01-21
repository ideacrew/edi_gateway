# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module InsurancePolicies
  module AcaIndividuals
    module EnrolledMembers
      # class to create enrolled members for an enrollment
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

        def initialize_enrolled_member(glue_enrollee, person_id, slcsp_member_premium, non_tobacco_use_premium = nil)
          ::InsurancePolicies::AcaIndividuals::EnrolledMember
            .new(ssn: glue_enrollee.person.authority_member.ssn,
                 dob: glue_enrollee.person.authority_member.dob,
                 gender: glue_enrollee.person.authority_member.gender,
                 relation_with_primary: glue_enrollee.rel_code,
                 person_id: person_id,
                 premium_schedule: { premium_amount: glue_enrollee.pre_amt,
                                     benchmark_ehb_premium_amount: slcsp_member_premium,
                                     non_tobacco_use_premium: non_tobacco_use_premium })
        end

        def store_enrolled_member(enrollment, glue_enrollee, person_hash, validated_params)
          enrolled_member = initialize_enrolled_member(
                                                        glue_enrollee,
                                                        person_hash[:id],
                                                        validated_params[:slcsp_member_premium],
                                                        validated_params[:non_tobacco_use_premium]
                                                      )

          case @type
          when "subscriber"
            enrollment.subscriber = enrolled_member
            enrollment.save!
          when "dependent"
            enrollment.dependents << enrolled_member
          end
          enrollment
        end

        def create(validated_params, person_hash, enrollment_hash, glue_enrollee)
          enrollment = find_enrollment(enrollment_hash)
          result = store_enrolled_member(enrollment, glue_enrollee, person_hash, validated_params)
          if result.present?
            enrollment_hash = result.to_hash
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
