# frozen_string_literal: true

# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/ClassLength
module IrsGroups
  # Parse CV3 family payload and store necessary information
  class CreateOrUpdateTaxHouseholdsAndGroups
    include Dry::Monads[:result, :do, :try]
    include EventSource::Command
    require 'dry/monads'
    require 'dry/monads/do'

    def call(params)
      validated_params = yield validate(params)
      @family = validated_params[:family]
      # @year = validated_params[:year]
      insurance_thh_groups = yield persist_tax_household_groups
      Success(insurance_thh_groups)
    end

    private

    def validate(params)
      return Failure("Family should not be blank") if params[:family].blank?
      # return Failure("Year cannot be blank") if params[:year].blank?

      Success(params)
    end

    def fetch_insurance_agreements
      primary_member = @family.family_members.detect { |member| member.is_primary_applicant == true }
      contract_holder = People::Persons::Find.new.call({ hbx_id: primary_member.person.hbx_id })
      return Failure("Unable to find contract holder") if contract_holder.failure?

      Success(InsurancePolicies::InsuranceAgreement.where(contract_holder_id: contract_holder.value![:id]))
    end

    def fetch_irs_group
      result = fetch_insurance_agreements
      return if result.failure?

      result.success&.flat_map(&:insurance_policies)&.pluck(:irs_group_id)&.compact&.first
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/MethodLength
    def build_tax_household_and_members(tax_household)
      result = {
        hbx_id: tax_household.hbx_id,
        allocated_aptc: { cents: tax_household.allocated_aptc&.cents,
                          currency_iso: tax_household.allocated_aptc&.currency_iso },
        max_aptc: { cents: tax_household.allocated_aptc&.cents,
                    currency_iso: tax_household.allocated_aptc&.currency_iso },
        start_date: tax_household.start_date,
        end_date: tax_household.end_date,
        is_eligibility_determined: tax_household.is_eligibility_determined,
        tax_household_members: build_tax_household_members(tax_household)
      }

      if tax_household.yearly_expected_contribution.present?
        result.merge!(yearly_expected_contribution: {
                        cents: tax_household.yearly_expected_contribution&.cents,
                        currency_iso: tax_household.yearly_expected_contribution&.currency_iso
                      })
      end
      result
    end
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/MethodLength

    def build_tax_household_members(tax_household)
      tax_household.tax_household_members.collect do |thh_member|
        tax_household_member_hash(thh_member)
      end
    end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    def tax_household_member_hash(thh_member)
      result = {
        is_subscriber: thh_member.is_subscriber,
        tax_filer_status: thh_member.tax_filer_status,
        product_eligibility_determination: {
          is_ia_eligible: thh_member.product_eligibility_determination.is_ia_eligible,
          is_medicaid_chip_eligible: thh_member.product_eligibility_determination.is_medicaid_chip_eligible,
          is_non_magi_medicaid_eligible: thh_member.product_eligibility_determination.is_non_magi_medicaid_eligible,
          is_totally_ineligible: thh_member.product_eligibility_determination.is_totally_ineligible,
          is_without_assistance: thh_member.product_eligibility_determination.is_without_assistance
        },
        family_member_reference: {
          relation_with_primary: thh_member.family_member_reference.relation_with_primary,
          family_member_hbx_id: thh_member.family_member_reference.family_member_hbx_id
        }
      }

      if thh_member.slcsp_benchmark_premium.present?
        result.merge!(slcsp_benchmark_premium: { cents: thh_member.slcsp_benchmark_premium&.cents,
                                                 currency_iso: thh_member.slcsp_benchmark_premium&.currency_iso })
      end
      result
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength

    # def fetch_thh_groups_for_year(tax_household_groups)
    #   tax_household_groups.select do |thh_group|
    #     thh_group.start_on.between?(Date.new(@year, 1, 1), Date.new(@year, 12, 31))
    #   end
    # end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/MethodLength
    def persist_tax_household_groups
      return Success(true) if @family.tax_household_groups.blank?

      tax_household_groups = @family.tax_household_groups
      return Success(true) if tax_household_groups.blank?

      tax_household_groups.each do |tax_hh_group|
        insurance_thh_group = InsurancePolicies::AcaIndividuals::TaxHouseholdGroups::Find
                              .new.call({ scope_name: :by_hbx_id, criterion: tax_hh_group.hbx_id })
        next insurance_thh_group if insurance_thh_group.success?

        thh_and_members_params = tax_hh_group.tax_households.collect do |tax_household|
          build_tax_household_and_members(tax_household)
        end
        irs_group_id = fetch_irs_group
        return Failure("Unable to find IRS group for family #{@family.hbx_id}") if irs_group_id.blank?

        thh_group_params = { hbx_id: tax_hh_group.hbx_id, start_on: tax_hh_group.start_on,
                             end_on: tax_hh_group.end_on, application_hbx_id: tax_hh_group.application_hbx_id,
                             assistance_year: tax_hh_group.assistance_year, tax_households: thh_and_members_params,
                             irs_group_id: irs_group_id }

        thh_group_hash = InsurancePolicies::AcaIndividuals::TaxHouseholdGroups::Create.new.call(thh_group_params)
        return Failure("Unable to persist thh groups") if thh_group_hash.failure?

        persist_tax_households(tax_hh_group.tax_households, thh_group_hash.value!)
      end
      Success(true)
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/MethodLength

    def persist_tax_households(tax_households, thh_group_hash)
      tax_households.each do |tax_household|
        insurance_thh = InsurancePolicies::AcaIndividuals::TaxHouseholds::Find
                        .new.call({ scope_name: :by_hbx_id, criterion: tax_household.hbx_id })
        next insurance_thh if insurance_thh.success?

        thh_params = build_tax_household_and_members(tax_household)
        thh_params.merge!(tax_household_group: thh_group_hash)
        insurance_thh_hash = InsurancePolicies::AcaIndividuals::TaxHouseholds::Create.new.call(thh_params)
        return Failure("Unable to persist tax_households") if insurance_thh_hash.failure?

        persist_tax_household_members(tax_household, insurance_thh_hash.value!)
      end
    end

    def persist_tax_household_members(tax_household, insurance_thh_hash)
      tax_household.tax_household_members.each do |thh_member|
        person = find_or_create_person(thh_member)
        thh_member_params = tax_household_member_hash(thh_member)
        thh_member_params.merge!(tax_household: insurance_thh_hash, person: person.value!)
        InsurancePolicies::AcaIndividuals::TaxHouseholdMembers::Create.new.call(thh_member_params)
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
