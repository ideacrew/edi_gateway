# frozen_string_literal: true

# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/ClassLength
# Module to create enrollments from cv3
module IrsGroups
  # persist insurance agreements and nested models
  class CreateOrUpdateEnrollmentsForPolicies
    include Dry::Monads[:result, :do, :try]
    include EventSource::Command

    def call(params)
      validated_params = yield validate(params)
      @family = validated_params[:family]
      @year = validated_params[:year]
      result = yield persist_enrollments

      Success(result)
    end

    private

    def validate(params)
      return Failure("Family should not be blank") if params[:family].blank?
      return Failure("Year cannot be blank") if params[:year].blank?

      Success(params)
    end

    def fetch_insurance_agreements
      primary_member = @family.family_members.detect { |member| member.is_primary_applicant == true }
      contract_holder = People::Persons::Find.new.call({ hbx_id: primary_member.person.hbx_id })
      return Failure("Unable to find contract holder") if contract_holder.failure?

      InsurancePolicies::InsuranceAgreement.where(contract_holder_id: contract_holder.value![:id])
    end

    def build_enrollment_and_member_hash(enrollment)
      {
        hbx_id: enrollment.hbx_id,
        effective_on: enrollment.effective_on,
        aasm_state: enrollment.aasm_state,
        terminated_on: enrollment.terminated_on,
        market_place_kind: enrollment.market_place_kind,
        enrollment_period_kind: enrollment.enrollment_period_kind,
        product_kind: enrollment.product_kind,
        applied_aptc_amount: { cents: enrollment.applied_aptc_amount&.cents,
                               currency_iso: enrollment.applied_aptc_amount&.currency_iso },
        total_premium: enrollment.total_premium,
        hbx_enrollment_members: build_enrollment_members_hash(enrollment.hbx_enrollment_members),
        product_reference: build_product_reference(enrollment.product_reference),
        issuer_profile_reference: build_issuer_profile_reference(enrollment.issuer_profile_reference)
      }
    end

    def build_enrollment_members_hash(enrollment_members)
      enrollment_members.collect do |enr_member|
        enr_member_hash(enr_member)
      end
    end

    def enr_member_hash(enr_member)
      result = {
        family_member_reference: {
          relation_with_primary: enr_member.family_member_reference.relation_with_primary,
          family_member_hbx_id: enr_member.family_member_reference.family_member_hbx_id
        },
        is_subscriber: enr_member.is_subscriber,
        coverage_start_on: enr_member.coverage_start_on,
        coverage_end_on: enr_member.coverage_end_on,
        eligibility_date: enr_member.eligibility_date
      }
      if enr_member.slcsp_member_premium.present?
        result.merge!(slcsp_member_premium: { cents: enr_member.slcsp_member_premium&.cents,
                                              currency_iso: enr_member.slcsp_member_premium&.currency_iso })
      end
      result
    end

    # rubocop:disable Metrics/MethodLength
    def build_product_reference(product_reference)
      result = {
        hios_id: product_reference.hios_id,
        name: product_reference.name,
        active_year: product_reference.active_year,
        is_dental_only: product_reference.is_dental_only,
        metal_level: product_reference.metal_level,
        benefit_market_kind: product_reference.benefit_market_kind,
        product_kind: product_reference.product_kind,
        issuer_profile_reference: build_issuer_profile_reference(product_reference.issuer_profile_reference)
      }
      if product_reference.family_rated_premiums.present?
        result.merge!(family_rated_premiums: {
                        exchange_provided_code: product_reference.family_rated_premiums.exchange_provided_code,
                        primary_enrollee: product_reference.family_rated_premiums.primary_enrollee,
                        primary_enrollee_one_dependent: product_reference.family_rated_premiums
                                                                         .primary_enrollee_one_dependent,
                        primary_enrollee_many_dependent: product_reference.family_rated_premiums
                                                                          .primary_enrollee_many_dependent
                      })
      end

      if product_reference.pediatric_dental_ehb.present?
        result.merge!(pediatric_dental_ehb: product_reference.pediatric_dental_ehb)
      end
      result
    end
    # rubocop:enable Metrics/MethodLength

    def build_issuer_profile_reference(issuer_profile_reference)
      {
        hbx_id: issuer_profile_reference.hbx_id,
        name: issuer_profile_reference.name,
        abbrev: issuer_profile_reference.abbrev
      }
    end

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/PerceivedComplexity
    # rubocop:disable Metrics/CyclomaticComplexity
    def persist_enrollments
      insurance_agreements = fetch_insurance_agreements
      insurance_agreements.each do |insurance_agreement|
        next if insurance_agreement.insurance_policies.blank?

        insurance_agreement.insurance_policies.each do |insurance_policy|
          insurance_policy_enrollment_ids = insurance_policy.hbx_enrollment_ids
          enrollments_from_cv3 = fetch_enrollments_from_cv3(insurance_policy_enrollment_ids)
          next if enrollments_from_cv3.blank?

          enrollments_from_cv3.each do |enrollment|
            enrollment_hash = InsurancePolicies::AcaIndividuals::Enrollments::Find
                              .new.call({ scope_name: :by_hbx_id, criterion: enrollment.hbx_id })
            next enrollment_hash.value! if enrollment_hash.success?

            enrollment_and_member_hash = build_enrollment_and_member_hash(enrollment)
            enrollment_and_member_hash.merge!(insurance_policy: insurance_policy.to_hash)
            new_enr_hash = InsurancePolicies::AcaIndividuals::Enrollments::Create.new.call(enrollment_and_member_hash)
            return Failure("Unable to create enrollment") if new_enr_hash.failure?

            persist_subscriber(insurance_policy, enrollment.hbx_enrollment_members, new_enr_hash.value!)
            persist_dependents(insurance_policy, enrollment.hbx_enrollment_members, new_enr_hash.value!)
            if enrollment.tax_households_references.blank?
              tax_household = create_tax_hh_group_and_households(enrollment, insurance_policy)
              create_enrollments_tax_households(enrollment, new_enr_hash.value!, tax_household)
            else
              ::IrsGroups::CreateOrUpdateEnrollmentsTaxHouseholds.new.call({ enrollment: enrollment,
                                                                             family: @family })
            end
          end
        end
      end
      Success(true)
    end
    # rubocop:enable Metrics/PerceivedComplexity
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/MethodLength

    def persist_subscriber(insurance_policy, enrollment_members, insurance_enr_hash)
      subscriber = enrollment_members.detect { |member| member.is_subscriber == true }
      return Success(true) if subscriber.blank?

      glue_enrollee = fetch_person_from_glue(insurance_policy, subscriber)
      params = enr_member_hash(subscriber)
      person = find_or_create_person(subscriber)
      params.merge!(person_hash: person.value!, enrollment_hash: insurance_enr_hash, glue_enrollee: glue_enrollee,
                    type: "subscriber")
      InsurancePolicies::AcaIndividuals::EnrolledMembers::Create.new.call(params)
    end

    def persist_dependents(insurance_policy, enrollment_members, insurance_enr_hash)
      dependents = enrollment_members.select { |member| member.is_subscriber == false }
      return Success(true) if dependents.blank?

      dependents.each do |dependent|
        glue_enrollee = fetch_person_from_glue(insurance_policy, dependent)
        params = enr_member_hash(dependent)
        person = find_or_create_person(dependent)
        params.merge!(person_hash: person.value!, enrollment_hash: insurance_enr_hash, glue_enrollee: glue_enrollee,
                      type: "dependent")

        InsurancePolicies::AcaIndividuals::EnrolledMembers::Create.new.call(params)
      end
    end

    # rubocop:disable Metrics/MethodLength
    def create_tax_hh_group_and_households(enrollment, insurance_policy)
      end_on = enrollment.aasm_state == "coverage_canceled" ? enrollment.effective_on : enrollment.terminated_on
      tax_hh_group = ::InsurancePolicies::AcaIndividuals::TaxHouseholdGroup
                     .create!({ start_on: enrollment.effective_on,
                                end_on: end_on,
                                is_aqhp: false,
                                hbx_id: 9.times.map { rand(9) }.join,
                                assistance_year: @year,
                                irs_group_id: insurance_policy.irs_group.id })

      tax_household = ::InsurancePolicies::AcaIndividuals::TaxHousehold
                      .create!({ is_aqhp: false,
                                 hbx_id: 9.times.map { rand(9) }.join,
                                 start_on: enrollment.effective_on,
                                 tax_household_group_id: tax_hh_group&.id })

      enrollment.hbx_enrollment_members.each do |member|
        person = find_or_create_person(member)
        ::InsurancePolicies::AcaIndividuals::TaxHouseholdMember
          .create!({ hbx_id: 9.times.map { rand(9) }.join,
                     is_subscriber: member.is_subscriber,
                     is_uqhp_eligible: true,
                     person_id: person.value![:id],
                     tax_household_id: tax_household.id })
      end
      tax_household
    end
    # rubocop:enable Metrics/MethodLength

    def create_enrollments_tax_households(enrollment, enrollment_hash, tax_household)
      enr_tax_household = ::InsurancePolicies::AcaIndividuals::EnrollmentsTaxHouseholds
                          .create!(tax_household_id: tax_household.id,
                                   enrollment_id: enrollment_hash[:id])
      enrollment.hbx_enrollment_members.each do |member|
        person = find_or_create_person(member)
        ::InsurancePolicies::AcaIndividuals::EnrolledMembersTaxHouseholdMembers
          .create!({ person_id: person.value![:id],
                     enrollments_tax_households_id: enr_tax_household.id })
      end
    end

    def fetch_enrollments_from_cv3(insurance_policy_enrollment_ids)
      @family.households.first.hbx_enrollments.select do |enrollment|
        insurance_policy_enrollment_ids.include?(enrollment.hbx_id) &&
          enrollment.effective_on.between?(Date.new(@year, 1, 1), Date.new(2023, 12, 31))
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

    def fetch_person_from_glue(insurance_policy, enr_member)
      policy = Policy.where(eg_id: insurance_policy.policy_id).first
      policy.enrollees.detect do |enrollee|
        enrollee.m_id == enr_member.family_member_reference.family_member_hbx_id
      end
    end
  end
end
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/ClassLength
