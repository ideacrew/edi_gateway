# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'bigdecimal'
require "aca_entities/functions/age_on"

# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/ClassLength
module Tax1095a
  module Transformers
    module InsurancePolicies
      # Family params to be transformed.
      class Cv3Family
        include EventSource::Command
        include Dry::Monads[:result, :do]

        TAX_FORM_TYPES = %w[IVL_TAX Corrected_IVL_TAX IVL_VTA IVL_CAP].freeze

        # params {tax_year: ,tax_form_type:, irs_group_id: }
        def call(params)
          tax_year, tax_form_type, irs_group_id = yield validate(params)
          irs_group = yield fetch_irs_group(irs_group_id)
          insurance_agreements = yield fetch_insurance_agreements(irs_group)
          cv3_payload = yield construct_cv3_family(irs_group, insurance_agreements, tax_form_type)
          valid_cv3_payload = yield validate_payload(cv3_payload)
          entity_cv3_payload = yield initialize_entity(valid_cv3_payload)
          result = yield publish_payload(tax_year, tax_form_type, entity_cv3_payload)

          Success(result)
        end

        private

        def validate(params)
          tax_form_type = params[:tax_form_type]
          tax_year = params[:tax_year]
          irs_group_id = params[:irs_group_id]
          Failure("Valid tax form type is not present") unless TAX_FORM_TYPES.include?(tax_form_type)
          Failure("tax_year is not present") unless tax_year.present?
          Failure("irs_group_id is not present") unless irs_group_id.present?
          Success([tax_year, tax_form_type, irs_group_id])
        end

        def validate_payload(cv3_payload)
          result = AcaEntities::Contracts::Families::FamilyContract.new.call(cv3_payload)
          if result.success?
            Success(result)
          else
            Failure("Payload is invalid due to #{result.errors.to_h}")
          end
        end

        def initialize_entity(cv3_payload)
          result = Try do
            AcaEntities::Families::Family.new(cv3_payload.to_h)
          end

          result.or do |e|
            Failure(e)
          end
        end

        def fetch_irs_group(irs_group_id)
          result = ::InsurancePolicies::AcaIndividuals::IrsGroup.where(:irs_group_id => irs_group_id)
          Failure("Unable to fetch IRS group for irs_group_id: #{irs_group_id}") unless result.present?
          Success(result.first)
        end

        def fetch_insurance_agreements(irs_group)
          result = irs_group.insurance_agreements

          Failure("Unable to fetch insurance_agreements for irs_group_id: #{irs_group.id}") unless result.present?
          Success(result)
        end

        def construct_cv3_family(irs_group, insurance_agreements, tax_form_type)
          contract_holder = insurance_agreements.first.contract_holder
          result = {
            hbx_id: irs_group.irs_group_id,
            family_members: construct_family_members(contract_holder, irs_group.aca_individual_insurance_policies),
            households: construct_households(irs_group, insurance_agreements, tax_form_type)
          }

          Success(result)
        end

        def fetch_all_members(contract_holder, policies)
          all_enrolled_members = [policies.flat_map(&:enrollments).flat_map(&:subscriber) +
            policies.flat_map(&:enrollments).flat_map(&:dependents)].flatten.uniq(&:person_id)
          [[contract_holder] + all_enrolled_members.map(&:person)].flatten.uniq
        end

        def construct_family_members(contract_holder, policies)
          all_members = fetch_all_members(contract_holder, policies)
          all_members.collect do |insurance_person|
            glue_person = fetch_person_from_glue(insurance_person)
            {
              is_primary_applicant: contract_holder == insurance_person,
              person: construct_person_hash(insurance_person, glue_person)
            }
          end
        end

        def construct_households(irs_group, insurance_agreements, tax_form_type)
          [
            start_date: irs_group.start_on,
            is_active: true,
            coverage_households: construct_coverage_households,
            insurance_agreements: construct_insurance_agreements(insurance_agreements, tax_form_type)
          ]
        end

        def construct_coverage_households
          [{
            is_immediate_family: true,
            coverage_household_members: []
          }]
        end

        def construct_insurance_agreements(insurance_agreements, tax_form_type)
          insurance_agreements = insurance_agreements.uniq(&:id)

          # rejecting dental agreements
          agreement = insurance_agreements.reject do |insurance_agreement|
            insurance_agreement if %w(010286541).include?(insurance_agreement.insurance_provider.fein)
          end
          agreement.collect do |insurance_agreement|
            {
              plan_year: insurance_agreement.plan_year,
              contract_holder: construct_contract_holder(insurance_agreement.contract_holder),
              insurance_provider: construct_insurance_provider(insurance_agreement.insurance_provider),
              insurance_policies: construct_insurance_policies(insurance_agreement.insurance_policies,
                                                               insurance_agreement.plan_year, tax_form_type)
            }
          end
        end

        def construct_person_hash(insurance_person, glue_person)
          authority_member = glue_person.authority_member
          {
            hbx_id: glue_person.authority_member_id,
            person_name: { first_name: glue_person.name_first, last_name: glue_person.name_last },
            person_demographics: { gender: authority_member.gender,
                                   encrypted_ssn: encrypt_ssn(authority_member.ssn),
                                   dob: authority_member.dob },
            person_health: {},
            is_active: true,
            addresses: construct_addresses(insurance_person),
            emails: construct_emails(insurance_person)
          }
        end

        def address_result(result, address, is_contract_holder)
          if is_contract_holder
            result.merge!(state_abbreviation: address.state_abbreviation,
                          zip_code: address.zip_code)
          else
            result.merge!(state: address.state_abbreviation,
                          zip: address.zip_code)
          end
        end

        def construct_addresses(insurance_person, is_contract_holder: false)
          insurance_person.addresses.collect do |address|
            result = {
              kind: address.kind,
              address_1: address.address_1,
              address_2: address.address_2,
              address_3: address.address_3,
              city: address.city_name,
              county_name: address.county_name
            }
            address_result(result, address, is_contract_holder)
          end
        end

        def construct_emails(insurance_person)
          insurance_person.emails.collect do |email|
            {
              kind: email.kind,
              address: email.address
            }
          end
        end

        def fetch_person_from_glue(people_person)
          Person.where(authority_member_id: people_person.hbx_id).first
        end

        def construct_contract_holder(contract_holder)
          glue_person = fetch_person_from_glue(contract_holder)
          authority_member = glue_person.authority_member
          {
            hbx_id: contract_holder.hbx_id,
            person_name: { first_name: contract_holder.name.first_name,
                           last_name: contract_holder.name.last_name },
            encrypted_ssn: encrypt_ssn(authority_member.ssn),
            dob: authority_member.dob,
            gender: authority_member.gender,
            addresses: construct_addresses(contract_holder, is_contract_holder: true)

          }
        end

        def construct_insurance_provider(insurance_provider)
          {
            title: insurance_provider.issuer_me_name,
            hios_id: insurance_provider.hios_id,
            fein: insurance_provider.fein,
            insurance_products: construct_insurance_products(insurance_provider.insurance_products)
          }
        end

        def construct_insurance_products(insurance_products)
          insurance_products.collect do |insurance_product|
            {
              name: insurance_product.name,
              hios_plan_id: insurance_product.hios_plan_id,
              plan_year: insurance_product.plan_year,
              coverage_type: insurance_product.coverage_type,
              metal_level: insurance_product.metal_level,
              market_type: insurance_product.market_type,
              ehb: insurance_product.ehb
            }
          end
        end

        def construct_insurance_policies(insurance_policies, year, tax_form_type)
          valid_policies = insurance_policies.reject do |insurance_policy|
            # TODO: support for all tax forms
            non_eligible_policy(insurance_policy, year, tax_form_type) if ["IVL_TAX", "IVL_CAP"].include?(tax_form_type)
          end

          return [] if valid_policies.empty?

          valid_policies.collect do |insurance_policy|
            {
              policy_id: insurance_policy.policy_id,
              insurance_product: construct_insurance_product(insurance_policy.insurance_product),
              hbx_enrollment_ids: insurance_policy.hbx_enrollment_ids,
              start_on: insurance_policy.start_on,
              end_on: insurance_policy.policy_end_on,
              enrollments: construct_enrollments(insurance_policy),
              aptc_csr_tax_households: construct_aptc_csr_tax_households(insurance_policy)
            }
          end
        end

        def encrypt_ssn(ssn)
          return unless ssn

          result = AcaEntities::Operations::Encryption::Encrypt.new.call({ value: ssn })
          result.success? ? result.value! : nil
        end

        def construct_enrollments(insurance_policy)
          enrollments = insurance_policy.enrollments.reject { |enr| enr.aasm_state == "coverage_canceled" }
          enrollments.collect do |enr|
            {
              start_on: enr.start_on,
              subscriber: construct_subscriber(enr.subscriber),
              dependents: construct_dependents(enr.dependents),
              total_premium_amount: enr.total_premium_amount&.to_hash,
              tax_households: construct_tax_households(enr),
              total_premium_adjustment_amount: enr.total_premium_adjustment_amount&.to_hash
            }
          end
        end

        def construct_tax_households(enrollment)
          tax_households = enrollment.tax_households
          tax_households.collect do |tax_household|
            enrolled_thh_members =  fetch_enrolled_thh_members([enrollment], tax_household)
            {
              hbx_id: tax_household.hbx_id,
              tax_household_members: construct_tax_household_members(tax_household, enrolled_thh_members)
            }
          end
        end

        def construct_tax_household_members(tax_household, enrolled_thh_members)
          enrolled_thh_members.collect do |enrolled_thh_member|
            thh_member = tax_household.tax_household_members.where(:person_id => enrolled_thh_member.person_id).first
            {
              family_member_reference: { family_member_hbx_id: enrolled_thh_member.person.hbx_id,
                                         relation_with_primary: enrolled_thh_member.relation_with_primary },
              tax_filer_status: thh_member.tax_filer_status,
              is_subscriber: thh_member.is_subscriber
            }
          end
        end

        def construct_subscriber(subscriber)
          person = subscriber.person
          {
            member: { hbx_id: person.hbx_id,
                      member_id: person.hbx_id,
                      person_name: { first_name: person.name.first_name,
                                     last_name: person.name.last_name,
                                     middle_name: person.name.middle_name } },
            dob: subscriber.dob,
            gender: subscriber.gender,
            addresses: construct_addresses(person),
            emails: construct_emails(person)
          }
        end

        def construct_dependents(dependents)
          dependents.collect do |dependent|
            person = dependent.person
            {
              member: { hbx_id: person.hbx_id,
                        member_id: person.hbx_id,
                        person_name: { first_name: person.name.first_name,
                                       last_name: person.name.last_name,
                                       middle_name: person.name.middle_name } },
              dob: subscriber.dob,
              gender: subscriber.gender,
              addresses: construct_addresses(person),
              emails: construct_emails(person)
            }
          end
        end

        def construct_insurance_product(product)
          {
            name: product.name,
            hios_plan_id: product.hios_plan_id,
            plan_year: product.plan_year,
            coverage_type: product.coverage_type,
            metal_level: product.metal_level,
            market_type: product.market_type,
            ehb: product.ehb
          }
        end

        def non_eligible_policy(pol, year, tax_form_type)
          return true if pol.aasm_state == "canceled"
          return true if pol.insurance_product.coverage_type == 'dental'
          return true if tax_form_type == "IVL_TAX" && pol.insurance_product.metal_level == "catastrophic"
          return true if pol.carrier_policy_id.blank?
          return true if pol.start_on.year.to_s != year

          false
        end

        def construct_aptc_csr_tax_households(insurance_policy)
          enrollments = insurance_policy.enrollments.reject { |enr| enr.aasm_state == "coverage_canceled" }
          tax_households = insurance_policy.irs_group.active_tax_households(insurance_policy.start_on.year)
          tax_households.collect do |tax_household|
            months_of_year = construct_coverage_information(insurance_policy, tax_household)

            {
              covered_individuals: construct_covered_individuals(enrollments, tax_household),
              months_of_year: months_of_year,
              annual_premiums: construct_annual_premiums(months_of_year)
            }
          end
        end

        def construct_covered_individuals(enrollments, tax_household)
          covered_individuals = fetch_enrolled_thh_members(enrollments, tax_household)
          covered_individuals.collect do |enrolled_member|
            glue_person = fetch_person_from_glue(enrolled_member.person)
            {
              coverage_start_on: enrolled_member.aca_individuals_enrollment.start_on,
              coverage_end_on: enrolled_member.aca_individuals_enrollment.insurance_policy.policy_end_on,
              person: construct_person_hash(enrolled_member.person, glue_person),
              relation_with_primary: enrolled_member.relation_with_primary,
              filer_status: fetch_tax_filer_status(tax_household, enrolled_member)
            }
          end
        end

        def construct_annual_premiums(months_of_year)
          coverage_information = months_of_year.collect { |m| m[:coverage_information] }

          result = [:tax_credit, :total_premium, :slcsp_benchmark_premium].each_with_object({}) do |k, output|
            output[k] = coverage_information.sum { |hash| hash[k] }
          end

          coverage_information.collect { |hash| hash.deep_transform_values!(&:to_hash) }
          result.deep_transform_values(&:to_hash)
        end

        # rubocop:disable Metrics/MethodLength
        def construct_coverage_information(insurance_policy, tax_household)
          (1..12).collect do |month|
            enrollments_for_month = ::InsurancePolicies::AcaIndividuals::InsurancePolicy
                                    .enrollments_for_month(month, insurance_policy.start_on.year, [insurance_policy])
            next if enrollments_for_month.blank?

            enrolled_members_in_month = fetch_enrolled_enrollment_members_per_thh_for_month(enrollments_for_month,
                                                                                            tax_household)
            slcsp, pre_amt_tot = enrollments_for_month.first&.fetch_npt_h36_prems(enrolled_members_in_month, month)
            aptc_tax_credit = if tax_household.is_aqhp == true
                                insurance_policy.fetch_aptc_tax_credit(enrollments_for_month, tax_household)
                              else
                                insurance_policy.fetch_aptc_tax_credit(enrollments_for_month)
                              end
            {
              month: Date::MONTHNAMES[month],
              coverage_information: { tax_credit: Money.new((BigDecimal(aptc_tax_credit) * 100).round, "USD"),
                                      total_premium: Money.new((BigDecimal(pre_amt_tot) * 100).round, "USD"),
                                      slcsp_benchmark_premium: Money.new((BigDecimal(slcsp) * 100).round, "USD") }

            }
          end
        end
        # rubocop:enable Metrics/MethodLength

        def fetch_enrolled_enrollment_members_per_thh_for_month(enrollments_for_month, tax_household)
          enrolled_members = [enrollments_for_month.flat_map(&:subscriber) + enrollments_for_month.flat_map(&:dependents)]
                             .flatten.uniq(&:person_id)
          tax_household_members = tax_household.tax_household_members

          enrolled_members.select { |enr_member| tax_household_members.map(&:person_id).include?(enr_member.person_id) }
        end

        def fetch_enrolled_thh_members(enrollments, tax_household)
          all_enrolled_members = [enrollments.flat_map(&:subscriber) + enrollments.flat_map(&:dependents)].flatten
          thh_members = tax_household.tax_household_members
          all_enrolled_members.select do |member|
            thh_members.map(&:person_id).include?(member.person_id)
          end
        end

        def fetch_tax_filer_status(tax_household, enrollee)
          thh_member = tax_household.tax_household_members.detect do |member|
            member.person_id == enrollee.person_id
          end

          thh_member&.tax_filer_status || "non_filer"
        end

        def publish_payload(_tax_year, _tax_form_type, _cv3_payload)
          Success(true)
        end
      end
    end
  end
end
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/ClassLength
