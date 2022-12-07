
module IrsGroups
  # Parse CV3 family payload and store necessary information
  class CreateOrUpdateTaxHouseholdGroups
    include Dry::Monads[:result, :do, :try]
    include EventSource::Command

    def call(params)
      validated_params = yield validate(params)
      @family = validated_params[:family]
      @irs_group = validated_params[:irs_group]
      # thh_groups_and_nested_data = yield construct_tax_household_groups
      # thh_enrollments_and_nested_data = yield construct_tax_household_enrollments
      result = yield persist_tax_household_groups

      Success(result)
    end

    private

    def validate(params)
      return Failure("Please pass in family entity") if params[:family].blank?
      return Failure("Irs Group is blank") if params[:irs_group].blank?

      Success(params)
    end

    def persist_tax_household_groups
      @family.tax_household_groups.each do |thh_group|
        edi_thh_group = @irs_group.tax_household_groups.find_or_create_by(hbx_id: thh_group.hbx_id)
        edi_thh_group.update!(start_on: thh_group.start_on, end_on: thh_group.end_on)
        persist_tax_households(thh_group, edi_thh_group)
      end

      Success(@irs_group)
    end

    def persist_tax_households(thh_group, edi_thh_group)
      thh_group.tax_households.each do |tax_household|
        edi_tax_household = edi_thh_group.tax_households.find_or_create_by(hbx_id: tax_household.hbx_id)
        edi_tax_household.update!(
          allocated_aptc: Money.new(tax_household.allocated_aptc&.cents, tax_household.allocated_aptc&.currency_iso),
          max_aptc: Money.new(tax_household.max_aptc&.cents, tax_household.max_aptc&.currency_iso),
          start_date: tax_household.start_date,
          end_date: tax_household.end_date)

        persist_tax_household_members(tax_household, edi_tax_household)
      end
    end

    def persist_tax_household_members(tax_household, edi_tax_household)
      tax_household.tax_household_members.each do |member|
        edi_thh_member = edi_tax_household
                           .tax_household_members
                           .find_or_create_by(person_hbx_id: member.family_member_reference.family_member_hbx_id)

        persist_member_details(edi_thh_member, member)
        magi_household_income = Money.new(
          member.product_eligibility_determination.magi_medicaid_monthly_household_income&.cents,
          member.product_eligibility_determination.magi_medicaid_monthly_household_income&.currency_iso
        )
        magi_medicaid_income_limit = Money.new(
          member.product_eligibility_determination.magi_medicaid_monthly_income_limit&.cents,
          member.product_eligibility_determination.magi_medicaid_monthly_income_limit&.currency_iso
        )
        slcsp_benchmark_premium = Money.new(member.slcsp_benchmark_premium&.cents,
                                            member.slcsp_benchmark_premium&.currency_iso)

        edi_thh_member
          .update!(is_subscriber: member.is_subscriber,
                   is_ia_eligible: member.product_eligibility_determination.is_ia_eligible,
                   is_medicaid_chip_eligible: member.product_eligibility_determination.is_medicaid_chip_eligible,
                   is_non_magi_medicaid_eligible: member.product_eligibility_determination.is_non_magi_medicaid_eligible,
                   is_totally_ineligible: member.product_eligibility_determination.is_totally_ineligible,
                   is_without_assistance: member.product_eligibility_determination.is_without_assistance,
                   magi_medicaid_monthly_household_income: magi_household_income,
                   medicaid_household_size: member.product_eligibility_determination.medicaid_household_size,
                   magi_medicaid_monthly_income_limit: magi_medicaid_income_limit,
                   magi_as_percentage_of_fpl: member.product_eligibility_determination.magi_as_percentage_of_fpl,
                   magi_medicaid_category: member.product_eligibility_determination.magi_medicaid_category,
                   csr: member.product_eligibility_determination.csr,
                   slcsp_benchmark_premium: slcsp_benchmark_premium,
                   tax_filer_status: member.tax_filer_status,
                   relation_with_primary: member.family_member_reference.relation_with_primary)
      end
    end

    def persist_member_details(edi_thh_member, member)
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
        edi_thh_member.update!(member_id: member.id, dob: payload[:dob], gender: payload[:gender],
                               person_name: payload[:person_name])
      else
        edi_thh_member.member = InsurancePolicies::AcaIndividuals::Member.new(payload)
        edi_thh_member.member.save!
      end
    end

    def fetch_person_details_from_family(member)
      @family.family_members.detect do |family_member|
        family_member.person.hbx_id == member.family_member_reference.family_member_hbx_id
      end
    end

    # def construct_tax_household_groups
    #   payload = @family.tax_household_groups.collect do |tax_household_group|
    #     {
    #       tax_household_group_hbx_id: tax_household_group.hbx_id,
    #       start_on: tax_household_group.start_on,
    #       end_on: tax_household_group.end_on,
    #       assistance_year: tax_household_group.assistance_year,
    #       source: tax_household_group.source,
    #       tax_households: construct_thhs_from_groups(tax_household_group)
    #     }
    #   end
    #
    #   Success(payload)
    # end
    #
    # def construct_thhs_from_groups(tax_household_group)
    #   tax_household_group.tax_households.collect do |tax_household|
    #     {
    #       tax_household_hbx_id: tax_household.hbx_id,
    #       allocated_aptc: Money.new(tax_household.allocated_aptc&.cents, tax_household.allocated_aptc&.currency_iso),
    #       max_aptc: Money.new(tax_household.max_aptc&.cents, tax_household.max_aptc&.currency_iso),
    #       start_date: tax_household.start_date,
    #       end_date: tax_household.end_date,
    #       tax_household_members: construct_tax_household_members(tax_household)
    #     }
    #   end
    # end
    #
    # # rubocop:disable Metrics/MethodLength
    # # rubocop:disable Metrics/AbcSize
    # def construct_tax_household_members(tax_household)
    #   tax_household.tax_household_members.collect do |member|
    #     magi_household_income = Money.new(
    #       member.product_eligibility_determination.magi_medicaid_monthly_household_income&.cents,
    #       member.product_eligibility_determination.magi_medicaid_monthly_household_income&.currency_iso
    #     )
    #     magi_medicaid_income_limit = Money.new(
    #       member.product_eligibility_determination.magi_medicaid_monthly_income_limit&.cents,
    #       member.product_eligibility_determination.magi_medicaid_monthly_income_limit&.currency_iso
    #     )
    #     slcsp_benchmark_premium = Money.new(member.slcsp_benchmark_premium&.cents,
    #                                         member.slcsp_benchmark_premium&.currency_iso)
    #     {
    #       is_subscriber: member.is_subscriber,
    #       is_ia_eligible: member.product_eligibility_determination.is_ia_eligible,
    #       is_medicaid_chip_eligible: member.product_eligibility_determination.is_medicaid_chip_eligible,
    #       is_non_magi_medicaid_eligible: member.product_eligibility_determination.is_non_magi_medicaid_eligible,
    #       is_totally_ineligible: member.product_eligibility_determination.is_totally_ineligible,
    #       is_without_assistance: member.product_eligibility_determination.is_without_assistance,
    #       magi_medicaid_monthly_household_income: magi_household_income,
    #       medicaid_household_size: member.product_eligibility_determination.medicaid_household_size,
    #       magi_medicaid_monthly_income_limit: magi_medicaid_income_limit,
    #       magi_as_percentage_of_fpl: member.product_eligibility_determination.magi_as_percentage_of_fpl,
    #       magi_medicaid_category: member.product_eligibility_determination.magi_medicaid_category,
    #       csr: member.product_eligibility_determination.csr,
    #       slcsp_benchmark_premium: slcsp_benchmark_premium,
    #       tax_filer_status: member.tax_filer_status,
    #       person_hbx_id: member.family_member_reference.family_member_hbx_id,
    #       relation_with_primary: member.family_member_reference.relation_with_primary,
    #       member: construct_member_details(member)
    #     }
    #   end
    # end
    #
    # def construct_member_details(member)
    #   family_member = fetch_person_details_from_family(member)
    #   {
    #     hbx_member_id: member.family_member_reference.family_member_hbx_id,
    #     person_name: { first_name: member.family_member_reference.first_name,
    #                    last_name: member.family_member_reference.last_name },
    #     dob: family_member.person.person_demographics.dob,
    #     gender: family_member.person.person_demographics.gender
    #   }
    # end
    #
    # # rubocop:enable Metrics/MethodLength
    # # rubocop:enable Metrics/AbcSize
    #
    # def construct_tax_household_enrollments
    #   payload = @family.households.last.hbx_enrollments.collect do |enr|
    #     next if enr.tax_households_references.blank?
    #
    #     enr.tax_households_references.collect do |thh_enr_reference|
    #
    #       household_benchmark_ehb_premium = Money.new(thh_enr_reference.household_benchmark_ehb_premium&.cents,
    #                                                   thh_enr_reference.household_benchmark_ehb_premium&.currency_iso)
    #       health_benchmark_ehb = Money.new(thh_enr_reference.household_health_benchmark_ehb_premium&.cents,
    #                                        thh_enr_reference.household_health_benchmark_ehb_premium&.currency_iso)
    #
    #       dental_benchmark_ehb = Money.new(thh_enr_reference.household_dental_benchmark_ehb_premium&.cents,
    #                                        thh_enr_reference.household_dental_benchmark_ehb_premium&.currency_iso)
    #       available_aptc = Money.new(thh_enr_reference.available_max_aptc&.cents,
    #                                  thh_enr_reference.available_max_aptc&.currency_iso)
    #
    #       applied_aptc = Money.new(thh_enr_reference.applied_aptc&.cents,
    #                                thh_enr_reference.applied_aptc&.currency_iso)
    #       {
    #         tax_household_hbx_id: thh_enr_reference.tax_household_reference.hbx_id,
    #         enrollment_hbx_id: thh_enr_reference.hbx_enrollment_reference.hbx_id,
    #         household_benchmark_ehb_premium: household_benchmark_ehb_premium,
    #         health_product_hios_id: thh_enr_reference.health_product_hios_id,
    #         dental_product_hios_id: thh_enr_reference.dental_product_hios_id,
    #         household_health_benchmark_ehb_premium: health_benchmark_ehb,
    #         household_dental_benchmark_ehb_premium: dental_benchmark_ehb,
    #         applied_aptc: applied_aptc,
    #         available_max_aptc: available_aptc,
    #         tax_household_members_enrollment_members: construct_thh_members_enrollment_members(thh_enr_reference)
    #       }
    #     end
    #   end
    #
    #   Success(payload.flatten!)
    # end
    #
    # def construct_thh_members_enrollment_members(thh_enr_reference)
    #   thh_enr_reference.tax_household_members_enrollment_members.collect do |thh_member_enr_member|
    #     {
    #       person_hbx_id: thh_member_enr_member.family_member_reference.person_hbx_id,
    #       age_on_effective_date: thh_member_enr_member.age_on_effective_date,
    #       relationship_with_primary: thh_member_enr_member.relationship_with_primary,
    #       date_of_birth: thh_member_enr_member.date_of_birth
    #     }
    #   end
    # end
    #
    # def persist_thh_groups(thh_groups)
    #   thh_groups.each do |group|
    #     thh_group = @irs_group.tax_household_groups.find_or_create_by(tax_household_group_hbx_id: group[:tax_household_group_hbx_id])
    #     thh_group.update!(start_on: group[:start_on], end_on: group[:end_on])
    #     @irs_group.tax_household_groups << InsurancePolicies::AcaIndividuals::TaxHouseholdGroup.new(group)
    #     @irs_group.save!
    #   end
    #   Success(@irs_group)
    # end
    #
    # def persist_thh_enrollments(thh_enrollments)
    #   thh_enrollments.each do |thh_enr|
    #     enr = InsurancePolicies::AcaIndividuals::TaxHouseholdEnrollment.new(thh_enr)
    #     enr.save!
    #   end
    #
    #   Success(@irs_group)
    # end
    #
    # def fetch_person_details_from_family(member)
    #   binding.pry
    #   @family.family_members.detect{|family_member| family_member.person.hbx_id == member.family_member_reference.family_member_hbx_id }
    # end
  end
end
