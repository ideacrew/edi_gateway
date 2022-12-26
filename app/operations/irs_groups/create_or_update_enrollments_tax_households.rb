# frozen_string_literal: true

# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/ClassLength

module IrsGroups
  # Parse CV3 family payload and store necessary information
  class CreateOrUpdateEnrollmentsTaxHouseholds
    include Dry::Monads[:result, :do, :try]
    include EventSource::Command
    require 'dry/monads'
    require 'dry/monads/do'

    def call(params)
      validated_params = yield validate(params)
      @family = validated_params[:family]
      insurance_thh_groups = yield persist(validated_params[:enrollment])
      Success(insurance_thh_groups)
    end

    private

    def validate(params)
      return Failure("Family should not be blank") if params[:family].blank?
      return Failure("enrollment should not be blank") if params[:enrollment].blank?

      Success(params)
    end

    def find_tax_household(tax_household_hbx_id)
      result = InsurancePolicies::AcaIndividuals::TaxHouseholds::Find.new.call({ scope_name: :by_hbx_id,
                                                                                 criterion: tax_household_hbx_id })
      return Failure("Unable to find tax household") if result.failure?

      result
    end

    def find_enrollment(enrollment_hbx_id)
      result = InsurancePolicies::AcaIndividuals::Enrollments::Find.new.call({ scope_name: :by_hbx_id,
                                                                               criterion: enrollment_hbx_id })
      return Failure("Unable to find enrollment") if result.failure?

      result
    end

    # rubocop:disable Metrics/PerceivedComplexity
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/CyclomaticComplexity
    def build_enrollments_thh_hash(enr_thh_reference)
      {
        tax_household_reference: { hbx_id: enr_thh_reference.tax_household_reference.hbx_id,
                                   max_aptc: { cents: enr_thh_reference.tax_household_reference.max_aptc&.cents,
                                               currency_iso: enr_thh_reference.tax_household_reference
                                                                              .max_aptc&.currency_iso },
                                   yearly_expected_contribution: {
                                     cents: enr_thh_reference.tax_household_reference
                                                             .yearly_expected_contribution&.cents,
                                     currency_iso: enr_thh_reference.tax_household_reference
                                                                    .yearly_expected_contribution&.currency_iso
                                   } },
        hbx_enrollment_reference: { hbx_id: enr_thh_reference.hbx_enrollment_reference.hbx_id,
                                    effective_on: enr_thh_reference.hbx_enrollment_reference.effective_on,
                                    aasm_state: enr_thh_reference.hbx_enrollment_reference.aasm_state,
                                    is_active: enr_thh_reference.hbx_enrollment_reference.is_active,
                                    market_place_kind: enr_thh_reference.hbx_enrollment_reference.market_place_kind,
                                    enrollment_period_kind: enr_thh_reference.hbx_enrollment_reference
                                                                             .enrollment_period_kind,
                                    product_kind: enr_thh_reference.hbx_enrollment_reference.product_kind },
        household_benchmark_ehb_premium: { cents: enr_thh_reference.household_benchmark_ehb_premium&.cents,
                                           currency_iso: enr_thh_reference.household_benchmark_ehb_premium
                                             &.currency_iso },
        applied_aptc: { cents: enr_thh_reference.applied_aptc&.cents,
                        currency_iso: enr_thh_reference.applied_aptc&.currency_iso },
        available_max_aptc: { cents: enr_thh_reference.available_max_aptc&.cents,
                              currency_iso: enr_thh_reference.available_max_aptc&.currency_iso },
        tax_household_members_enrollment_members: build_enrollment_thh_members_hash(enr_thh_reference
          .tax_household_members_enrollment_members)
      }
    end
    # rubocop:enable Metrics/PerceivedComplexity
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/CyclomaticComplexity

    def build_enrollment_thh_members_hash(enr_members_thh_members)
      enr_members_thh_members.collect do |enr_member_thh_member|
        enr_member_thh_member_hash(enr_member_thh_member)
      end
    end

    def enr_member_thh_member_hash(enr_member_thh_member)
      {
        hbx_enrollment_member: { family_member_reference: build_family_member_reference_hash(enr_member_thh_member
          .hbx_enrollment_member.family_member_reference),
                                 is_subscriber: enr_member_thh_member.hbx_enrollment_member.is_subscriber,
                                 eligibility_date: enr_member_thh_member.hbx_enrollment_member.eligibility_date,
                                 coverage_start_on: enr_member_thh_member.hbx_enrollment_member.coverage_start_on },
        tax_household_member: { family_member_reference: build_family_member_reference_hash(enr_member_thh_member
          .tax_household_member.family_member_reference) },
        age_on_effective_date: enr_member_thh_member.age_on_effective_date,
        family_member_reference: build_family_member_reference_hash(enr_member_thh_member.family_member_reference),
        relationship_with_primary: enr_member_thh_member.relationship_with_primary,
        date_of_birth: enr_member_thh_member.date_of_birth
      }
    end

    def build_family_member_reference_hash(fm_reference)
      {
        family_member_hbx_id: fm_reference.family_member_hbx_id,
        first_name: fm_reference.first_name,
        last_name: fm_reference.last_name,
        person_hbx_id: fm_reference.person_hbx_id,
        is_primary_family_member: fm_reference.is_primary_family_member,
        age: fm_reference.age,
        ssn: fm_reference.ssn,
        encrypted_ssn: fm_reference.encrypted_ssn,
        dob: fm_reference.dob,
        relation_with_primary: fm_reference.relation_with_primary
      }
    end

    def fetch_enrollments_from_cv3(insurance_policy_enrollment_ids)
      @family.households.first.hbx_enrollments.select do |enrollment|
        insurance_policy_enrollment_ids.include?(enrollment.hbx_id) &&
          enrollment.effective_on.between?(Date.new(@year, 1, 1), Date.new(2023, 12, 31))
      end
    end

    # rubocop:disable Metrics/MethodLength
    def persist(enrollment)
      return if enrollment.tax_households_references.blank?

      enrollment.tax_households_references.each do |enr_thh_reference|
        tax_household = find_tax_household(enr_thh_reference.tax_household_reference.hbx_id)
        enrollment = find_enrollment(enr_thh_reference.hbx_enrollment_reference.hbx_id)
        return Failure("Unable to find tax household of enrollment") if tax_household.failure? ||
                                                                        enrollment.failure?

        enrollment_tax_household_hash = InsurancePolicies::AcaIndividuals::EnrollmentsAndTaxHouseholds::Find
                                        .new.call({ scope_name: :by_enrollment_id_tax_household_id,
                                                    enrollment_id: enrollment.value![:id],
                                                    tax_household_id: tax_household.value![:id] })
        next enrollment_tax_household_hash.value! if enrollment_tax_household_hash.success?

        enr_thh_params_hash = build_enrollments_thh_hash(enr_thh_reference)
        enr_thh_params_hash.merge!(tax_household: tax_household.value!,
                                   enrollment: enrollment.value!)
        enrollment_tax_household_hash = InsurancePolicies::AcaIndividuals::EnrollmentsAndTaxHouseholds::Create
                                        .new.call(enr_thh_params_hash)
        return Failure("Unable to create enrollment tax household") if enrollment_tax_household_hash.failure?

        persist_enrolled_members_tax_household_members(enr_thh_reference, enrollment_tax_household_hash.value!)
      end
      Success(true)
    end
    # rubocop:enable Metrics/MethodLength

    def persist_enrolled_members_tax_household_members(thh_enr_reference, enrollment_tax_household_hash)
      thh_enr_reference.tax_household_members_enrollment_members.each do |thh_member_enr_member|
        insurance_thh_member = InsurancePolicies::AcaIndividuals::EnrolledMembersAndTaxHouseholdMembers::Find
                               .new.call({ scope_name: :by_person_hbx_id,
                                           person_hbx_id: thh_member_enr_member.family_member_reference
                                             .family_member_hbx_id })
        next insurance_thh_member if insurance_thh_member.success?

        person = find_or_create_person(thh_member_enr_member)
        enr_member_thh_member_params = enr_member_thh_member_hash(thh_member_enr_member)
        enr_member_thh_member_params.merge!(enrollment_tax_household: enrollment_tax_household_hash,
                                            person: person.value!)
        InsurancePolicies::AcaIndividuals::EnrolledMembersAndTaxHouseholdMembers::Create
          .new.call(enr_member_thh_member_params)
      end
    end

    def find_or_create_person(member)
      family_member = fetch_person_details_from_family(member)
      result = People::Persons::Find.new.call({ hbx_id: family_member.person.hbx_id })
      return result if result.success?

      result = People::Persons::Create.new.call({ person: family_member.person, type: "Enroll" })
      return Failure("unable to create or find person") if result.failure?

      result
    end

    def fetch_person_details_from_family(member)
      @family.family_members.detect do |family_member|
        family_member.person.hbx_id == member.family_member_reference.family_member_hbx_id
      end
    end
  end
end
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/ClassLength
