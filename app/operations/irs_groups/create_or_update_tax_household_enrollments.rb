
module IrsGroups
  # Parse CV3 family payload and store necessary information
  class CreateOrUpdateTaxHouseholdEnrollments
    include Dry::Monads[:result, :do, :try]
    include EventSource::Command
    require 'dry/monads'
    require 'dry/monads/do'

    def call(params)
      validated_params = yield validate(params)
      @family = validated_params[:family]
      result = yield persist_tax_household_enrollments

      Success(result)
    end

    private

    def validate(params)
      return Failure("Please pass in family entity") if params[:family].blank?

      Success(params)
    end

    def persist_tax_household_enrollments
      @family.households.last.hbx_enrollments.each do |enrollment|
        next if enrollment.tax_households_references.blank?

        enrollment.tax_households_references.each do |thh_enr_reference|
          household_benchmark_ehb_premium = Money.new(thh_enr_reference.household_benchmark_ehb_premium&.cents,
                                                      thh_enr_reference.household_benchmark_ehb_premium&.currency_iso)
          health_benchmark_ehb = Money.new(thh_enr_reference.household_health_benchmark_ehb_premium&.cents,
                                           thh_enr_reference.household_health_benchmark_ehb_premium&.currency_iso)

          dental_benchmark_ehb = Money.new(thh_enr_reference.household_dental_benchmark_ehb_premium&.cents,
                                           thh_enr_reference.household_dental_benchmark_ehb_premium&.currency_iso)
          available_aptc = Money.new(thh_enr_reference.available_max_aptc&.cents,
                                     thh_enr_reference.available_max_aptc&.currency_iso)

          applied_aptc = Money.new(thh_enr_reference.applied_aptc&.cents,
                                   thh_enr_reference.applied_aptc&.currency_iso)

          edi_thh_enrollment = InsurancePolicies::AcaIndividuals::TaxHouseholdEnrollment.find_or_create_by(
            tax_household_hbx_id: thh_enr_reference.tax_household_reference.hbx_id,
            enrollment_hbx_id: thh_enr_reference.hbx_enrollment_reference.hbx_id)

          edi_thh_enrollment.update!(
            household_benchmark_ehb_premium: household_benchmark_ehb_premium,
            health_product_hios_id: thh_enr_reference.health_product_hios_id,
            dental_product_hios_id: thh_enr_reference.dental_product_hios_id,
            household_health_benchmark_ehb_premium: health_benchmark_ehb,
            household_dental_benchmark_ehb_premium: dental_benchmark_ehb,
            applied_aptc: applied_aptc,
            available_max_aptc: available_aptc)

          persist_tax_household_member_enrollment_member(thh_enr_reference, edi_thh_enrollment)
        end
      end

      Success(true)
    end

    def persist_tax_household_member_enrollment_member(thh_enr_reference, edi_thh_enrollment)
      thh_enr_reference.tax_household_members_enrollment_members.each do |thh_enr_member|
        edi_thh_enr_member = edi_thh_enrollment.tax_household_members_enrollment_members
                                               .find_or_create_by(
                                                 person_hbx_id: thh_enr_member.family_member_reference.person_hbx_id)
        persist_member_details(edi_thh_enr_member, thh_enr_member)

        edi_thh_enr_member.update!(
          age_on_effective_date: thh_enr_member.age_on_effective_date,
          relationship_with_primary: thh_enr_member.relationship_with_primary,
          date_of_birth: thh_enr_member.date_of_birth
        )
      end
    end

    def persist_member_details(edi_thh_enr_member, member)
      family_member = fetch_person_details_from_family(member)

      payload = {
        hbx_member_id: member.family_member_reference.family_member_hbx_id,
        person_name: { first_name: member.family_member_reference.first_name,
                       last_name: member.family_member_reference.last_name },
        dob: family_member.person.person_demographics.dob,
        gender: family_member.person.person_demographics.gender
      }

      member = InsurancePolicies::AcaIndividuals::Member.where(hbx_member_id: payload[:hbx_member_id]).first

      if member.present?
        edi_thh_enr_member.update!(member_id: member.id, dob: payload[:dob], gender: payload[:gender],
                                   person_name: payload[:person_name])
      else
        edi_thh_enr_member.member = InsurancePolicies::AcaIndividuals::Member.new(payload)
        edi_thh_enr_member.member.save!
      end
    end

    def fetch_person_details_from_family(member)
      @family.family_members.detect do |family_member|
        family_member.person.hbx_id == member.family_member_reference.family_member_hbx_id
      end
    end
  end
end
