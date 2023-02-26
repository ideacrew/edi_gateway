# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module InsurancePolicies
  module AcaIndividuals
    module IrsGroups
      # Operation to create insurance policy
      class ConstructCv3Payload
        send(:include, Dry::Monads[:result, :do])

        def call(params)
          values = yield validate(params)
          insurance_agreements = yield find_insurance_agreements(values)
          family_members = yield construct_family_members(values, insurance_agreements)
          households = yield construct_households(values, insurance_agreements)
          insurance_policy_hash = yield construct_family_cv(values, family_members, households)

          Success(insurance_policy_hash)
        end

        private

        # h36 send all insurance agreements and policies
        # h41 filter agreements by affected policies and make sure to pull on affected policies from those agreements
        def validate(params)
          return Failure('tax_form_type is not present') unless params[:tax_form_type]

          # return Failure('tax_year is not present') unless params[:tax_year] # optional for h36
          return Failure('irs_group is not present') unless params[:irs_group]

          # return Failure('affected_policies is not present') unless params[:affected_policies] # optional

          Success(params)
        end

        def find_insurance_agreements(values)
          result =
            if values[:tax_year].present?
              values[:irs_group].insurance_agreements.select do |agreement|
                agreement.plan_year == values[:tax_year].to_s
              end
            else
              values[:irs_group].insurance_agreements
            end

          return Failure("Unable to fetch insurance_agreements for irs_group_id: #{values[:irs_group].id}") unless result.present?

          Success(result)
        end

        def construct_family_members(values, insurance_agreements)
          contract_holder = insurance_agreements.first.contract_holder
          policies = values[:irs_group].aca_individual_insurance_policies

          all_members = fetch_all_members(contract_holder, policies)
          family_member_hash =
            all_members.compact.collect do |insurance_person|
              glue_person = fetch_person_from_glue(insurance_person)
              {
                is_primary_applicant: contract_holder == insurance_person,
                person: construct_person_hash(insurance_person, glue_person)
              }
            end

          Success(family_member_hash)
        end

        def construct_households(values, insurance_agreements)
          households = [
            start_date: values[:irs_group].start_on,
            is_active: true,
            coverage_households: construct_coverage_households,
            insurance_agreements: construct_insurance_agreements(insurance_agreements, values[:tax_form_type])
          ]

          Success(households)
        end

        def construct_family_cv(values, family_members, households)
          Success(
            {
              hbx_id: values[:irs_group].family_hbx_assigned_id,
              irs_group_id: values[:irs_group].irs_group_id,
              family_members: family_members,
              households: households
            }
          )
        end

        def fetch_all_members(contract_holder, policies)
          all_enrolled_members =
            [
              policies.flat_map(&:enrollments).flat_map(&:subscriber) +
                policies.flat_map(&:enrollments).flat_map(&:dependents)
            ].flatten.uniq(&:person_id)
          [[contract_holder] + all_enrolled_members.map(&:person)].flatten.uniq
        end

        def construct_coverage_households
          [{ is_immediate_family: true, coverage_household_members: [] }]
        end

        def construct_insurance_agreements(insurance_agreements, tax_form_type)
          insurance_agreements = insurance_agreements.uniq(&:id)
          insurance_agreements.reject! do |insurance_agreement|
            insurance_agreement.insurance_policies.all? do |insurance_policy|
              insurance_policy.insurance_product.coverage_type == 'dental'
            end
          end

          insurance_agreements.collect do |insurance_agreement|
            {
              plan_year: insurance_agreement.plan_year,
              contract_holder: construct_contract_holder(insurance_agreement.contract_holder),
              insurance_provider: construct_insurance_provider(insurance_agreement.insurance_provider),
              insurance_policies:
                construct_insurance_policies(
                  insurance_agreement.insurance_policies,
                  insurance_agreement.plan_year,
                  tax_form_type
                )
            }
          end
        end

        def construct_person_hash(insurance_person, glue_person)
          authority_member = glue_person.authority_member
          {
            hbx_id: glue_person.authority_member_id,
            person_name: {
              first_name: glue_person.name_first,
              last_name: glue_person.name_last
            },
            person_demographics: person_demographics_hash(authority_member),
            person_health: {},
            is_active: true,
            addresses: construct_addresses(insurance_person),
            emails: construct_emails(insurance_person)
          }
        end

        def person_demographics_hash(authority_member)
          result = { gender: authority_member.gender, dob: authority_member.dob }
          result.merge!(encrypted_ssn: encrypt_ssn(authority_member.ssn)) if authority_member.ssn.present?
          result
        end

        def address_result(result, address, is_contract_holder)
          if is_contract_holder
            result.merge!(state_abbreviation: address.state_abbreviation, zip_code: address.zip_code)
          else
            result.merge!(state: address.state_abbreviation, zip: address.zip_code)
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
          insurance_person.emails.collect { |email| { kind: email.kind, address: email.address } }
        end

        def fetch_person_from_glue(people_person)
          Person.where(authority_member_id: people_person.hbx_id).first
        end

        def construct_contract_holder(contract_holder)
          glue_person = fetch_person_from_glue(contract_holder)
          authority_member = glue_person.authority_member
          result = {
            hbx_id: contract_holder.hbx_id,
            person_name: {
              first_name: contract_holder.name.first_name,
              last_name: contract_holder.name.last_name
            },
            dob: authority_member.dob,
            gender: authority_member.gender,
            addresses: construct_addresses(contract_holder, is_contract_holder: true)
          }
          result.merge!(encrypted_ssn: encrypt_ssn(authority_member.ssn)) if authority_member.ssn.present?
          result
        end

        def construct_insurance_provider(insurance_provider)
          {
            title: insurance_provider.title,
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
          valid_policies =
            insurance_policies.reject do |insurance_policy|
              # TODO: support for all tax forms
              non_eligible_policy(insurance_policy, year, tax_form_type) if %w[IVL_TAX IVL_CAP].include?(tax_form_type)
            end

          return [] if valid_policies.empty?

          valid_policies.collect do |insurance_policy|
            ::InsurancePolicies::AcaIndividuals::InsurancePolicies::ConstructCv3Payload
              .new
              .call(insurance_policy: insurance_policy)
              .success
          end
        end

        def non_eligible_policy(pol, year, tax_form_type)
          return true if tax_form_type == 'IVL_TAX' && pol.insurance_product.metal_level == 'catastrophic'
          return true if pol.carrier_policy_id.blank? && pol.aasm_state != 'canceled'
          return true if pol.insurance_product.coverage_type == 'dental'
          return true if pol.start_on.year.to_s != year

          false
        end

        def encrypt_ssn(ssn)
          result = AcaEntities::Operations::Encryption::Encrypt.new.call({ value: ssn })
          result.success? ? result.value! : ''
        end
      end
    end
  end
end
