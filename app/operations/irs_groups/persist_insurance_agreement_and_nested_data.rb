# frozen_string_literal: true

module IrsGroups
  # persist insurance agreements and nested models
  class PersistInsuranceAgreementAndNestedData
    include Dry::Monads[:result, :do, :try]
    include EventSource::Command

    def call(params)
      validated_params = yield validate(params)
      @family = validated_params[:family]
      @policies = validated_params[:policies]
      @irs_group = validated_params[:irs_group]
      @primary_person = validated_params[:primary_person]
      payload = yield construct_insurance_agreement_and_nested_data
      result = yield persist_insurance_agreement_and_nested_data(payload)

      Success(result)
    end

    private

    def validate(params)
      return Failure("Policies not present") if params[:policies].blank?
      return Failure("Family not present") if params[:family].blank?
      return Failure("Irs group not present") if params[:irs_group].blank?
      return Failure("primary_person not present") if params[:primary_person].blank?

      Success(params)
    end

    def construct_insurance_agreement_and_nested_data
      start_on = Date.new(@policies.first.plan.year, 1, 1)
      payload = {
        plan_year: @policies.first.plan.year,
        start_on: start_on,
        marketplace_segment_id: "#{@primary_person.hbx_id}-#{@policies.first.eg_id}-#{start_on.strftime('%Y%m%d')}",
        contract_holder: construct_member_payload(@primary_person, "self"),
        insurance_provider: construct_insurance_provider_payload,
        tax_households: construct_tax_households_payload
      }

      Success(payload)
    end

    def persist_insurance_agreement_and_nested_data(payload)
      @irs_group.insurance_agreements << InsurancePolicies::AcaIndividuals::InsuranceAgreement.new(payload)

      Success(@irs_group)
    end

    def construct_member_payload(person, relation_code)
      {
        hbx_member_id: person.hbx_id,
        ssn: person.person_demographics.ssn,
        dob: person.person_demographics.dob,
        gender: person.person_demographics.gender,
        relationship_code: relation_code,
        person_name: construct_person_name(person),
        addresses: construct_addresses(person),
        emails: construct_emails(person),
        phones: construct_phones(person)
      }
    end

    def construct_insurance_provider_payload
      carrier = @policies.first.carrier
      plan = @policies.first.plan
      {
        title: carrier.name,
        hios_id: plan.hios_plan_id.split("ME")[0],
        fein: carrier.fein,
        insurance_products: construct_insurance_products
      }
    end

    def construct_tax_households_payload
      household = @family.households.first
      if household.tax_households.present?
        household.tax_households.collect do |tax_household|
          {
            allocated_aptc: tax_household.allocated_aptc,
            max_aptc: tax_household.max_aptc,
            start_date: tax_household.start_date,
            end_date: tax_household.end_date,
            tax_household_members: construct_tax_household_members(tax_household)
          }
        end
      elsif household.coverage_households.present?
        household.coverage_households.collect do |coverage_household|
          {
            start_date: coverage_household.start_date,
            end_date: coverage_household.end_date,
            tax_household_members: construct_coverage_household_members(coverage_household)
          }
        end
      end
    end

    def construct_tax_household_members(tax_household)
      tax_household.tax_household_members.collect do |member|
        {
          is_ia_eligible: member.product_eligibility_determination.is_ia_eligible,
          is_medicaid_chip_eligible: member.product_eligibility_determination.is_medicaid_chip_eligible,
          is_non_magi_medicaid_eligible: member.product_eligibility_determination.is_non_magi_medicaid_eligible,
          is_totally_ineligible: member.product_eligibility_determination.is_totally_ineligible,
          is_without_assistance: member.product_eligibility_determination.is_without_assistance,
          magi_medicaid_monthly_household_income: member.product_eligibility_determination.magi_medicaid_monthly_household_income,
          medicaid_household_size: member.product_eligibility_determination.medicaid_household_size,
          magi_medicaid_monthly_income_limit: member.product_eligibility_determination.magi_medicaid_monthly_income_limit,
          magi_as_percentage_of_fpl: member.product_eligibility_determination.magi_as_percentage_of_fpl,
          magi_medicaid_category: member.product_eligibility_determination.magi_medicaid_category,
          csr: member.product_eligibility_determination.csr,
          slcsp_benchmark_premium: member.slcsp_benchmark_premium,
          tax_filer_status: member.tax_filer_status,
          person_hbx_id: fetch_member_hbx_id(member)
        }
      end
    end

    def construct_coverage_household_members(coverage_household)
      coverage_household.coverage_household_members.collect do |member|
        {
          person_hbx_id: fetch_member_hbx_id(member)
        }
      end
    end

    def fetch_member_hbx_id(member)
      family_member = @family.family_members.detect do |dependent|
        dependent.hbx_id == member.family_member_reference.family_member_hbx_id
      end

      person = family_member.person
      person.hbx_id
    end

    def construct_person_name(person)
      {
        first_name: person.person_name.first_name,
        last_name: person.person_name.last_name
      }
    end

    def construct_addresses(person)
      person.addresses.collect do |address|
        {
          kind: address.kind,
          address_1: address.address_1,
          address_2: address.address_2,
          address_3: address.address_3,
          city: address.city,
          county: address.county,
          state: address.state,
          zip: address.zip
        }
      end
    end

    def construct_emails(person)
      person.emails.collect do |email|
        {
          kind: email.kind,
          address: email.address
        }
      end
    end

    def construct_phones(person)
      person.phones.collect do |phone|
        {
          kind: phone.kind,
          country_code: phone.country_code,
          area_code: phone.area_code,
          number: phone.number,
          extension: phone.extension,
          primary: phone.primary,
          full_phone_number: phone.full_phone_number
        }
      end
    end

    def construct_insurance_products
      @policies.collect do |policy|
        {
          name: policy.plan.name
        }
      end
    end
  end
end
