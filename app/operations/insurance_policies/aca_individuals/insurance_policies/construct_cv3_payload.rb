# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module InsurancePolicies
  module AcaIndividuals
    module InsurancePolicies
      # rubocop:disable Metrics/ClassLength
      # Operation to create insurance policy
      class ConstructCv3Payload
        send(:include, Dry::Monads[:result, :do])

        def call(params)
          values = yield validate(params)
          insurance_product = yield construct_insurance_product(values[:insurance_policy])
          insurance_provider = yield construct_insurance_provider(values[:insurance_policy])
          enrollments = yield construct_enrollments(values[:insurance_policy])
          aptc_csr_tax_households = yield construct_aptc_csr_tax_households(values[:insurance_policy])
          insurance_policy_hash =
            yield construct_insurance_policy(
              values[:insurance_policy],
              insurance_product,
              enrollments,
              insurance_provider,
              aptc_csr_tax_households
            )

          Success(insurance_policy_hash)
        end

        private

        def validate(params)
          return Failure('insurance_policy required') unless params[:insurance_policy]

          Success(params)
        end

        def construct_insurance_product(insurance_policy)
          product = insurance_policy.insurance_product

          Success(
            {
              name: product.name,
              hios_plan_id: product.hios_plan_id,
              plan_year: product.plan_year,
              coverage_type: product.coverage_type,
              metal_level: product.metal_level,
              market_type: product.market_type,
              ehb: product.ehb
            }
          )
        end

        def construct_insurance_provider(insurance_policy)
          insurance_provider = insurance_policy.insurance_product.insurance_provider

          Success(
            {
              title: insurance_provider.title,
              hios_id: insurance_provider.hios_id,
              fein: insurance_provider.fein,
              insurance_products: construct_insurance_products(insurance_provider.insurance_products)
            }
          )
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

        def construct_enrollments(insurance_policy)
          enrollments = insurance_policy.enrollments.reject { |enr| enr.aasm_state == 'coverage_canceled' }
          enrollments_hash =
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

          Success(enrollments_hash)
        end

        def construct_aptc_csr_tax_households(insurance_policy)
          return Success([]) if insurance_policy.insurance_product.coverage_type == 'dental'

          enrollments = if insurance_policy.aasm_state == "canceled"
                          insurance_policy.enrollments
                        else
                          insurance_policy.enrollments.reject { |enr| enr.aasm_state == 'coverage_canceled' }
                        end
          @enrollments = enrollments
          tax_households = insurance_policy.effectuated_aptc_tax_households_with_unique_composition
          @tax_households = tax_households

          return Success([]) if tax_households.compact.blank?

          tax_households_hash =
            tax_households.collect do |tax_household|
              next unless any_thh_members_enrolled?(tax_household, enrollments)

              covered_individuals = construct_covered_individuals(enrollments, tax_household)
              months_of_year = construct_coverage_information(insurance_policy, covered_individuals, tax_household)
              {
                tax_household_members: construct_tax_household_members(tax_household),
                hbx_assigned_id: tax_household.hbx_id,
                primary_tax_filer_hbx_id: tax_household.primary_tax_filer_hbx_id,
                covered_individuals: covered_individuals,
                months_of_year: months_of_year.compact,
                annual_premiums: construct_annual_premiums(months_of_year)
              }
            end.compact

          Success(tax_households_hash)
        end

        def construct_tax_household_members(tax_household)
          tax_household.tax_household_members.collect do |thh_member|
            glue_person = fetch_person_from_glue(thh_member.person)
            result = {
              family_member_reference: {
                family_member_hbx_id: thh_member.person.hbx_id,
                relation_with_primary: thh_member.relation_with_primary,
                first_name: thh_member.person.name.first_name,
                last_name: thh_member.person.name.last_name,
                dob: glue_person&.authority_member&.dob
              },
              tax_filer_status: thh_member&.tax_filer_status,
              is_subscriber: thh_member&.is_subscriber || false
            }

            if glue_person&.authority_member&.ssn.present?
              result[:family_member_reference][:encrypted_ssn] = encrypt_ssn(glue_person&.authority_member&.ssn)
            end
            result
          end
        end

        def construct_insurance_policy(
          insurance_policy,
          insurance_product,
          enrollments,
          insurance_provider,
          aptc_csr_tax_households
        )
          Success(
            {
              policy_id: insurance_policy.policy_id,
              insurance_product: insurance_product,
              insurance_provider: insurance_provider,
              start_on: insurance_policy.start_on,
              end_on: insurance_policy.policy_end_on,
              aasm_state: insurance_policy.aasm_state.to_s,
              term_for_np: insurance_policy.term_for_np,
              enrollments: enrollments,
              aptc_csr_tax_households: aptc_csr_tax_households,
              carrier_policy_id: insurance_policy.carrier_policy_id
            }
          )
        end

        def construct_tax_households(enrollment)
          tax_households = enrollment.tax_households
          tax_households.collect do |tax_household|
            enrolled_thh_members = fetch_enrolled_thh_members([enrollment], tax_household)
            {
              hbx_id: tax_household.hbx_id,
              tax_household_members: construct_enrolled_tax_household_members(tax_household, enrolled_thh_members)
            }
          end
        end

        def construct_enrolled_tax_household_members(tax_household, enrolled_thh_members)
          enrolled_thh_members.collect do |enrolled_thh_member|
            thh_member = tax_household.tax_household_members.where(person_id: enrolled_thh_member.person_id).first
            {
              family_member_reference: {
                family_member_hbx_id: enrolled_thh_member.person.hbx_id,
                relation_with_primary: enrolled_thh_member.relation_with_primary
              },
              tax_filer_status: thh_member&.tax_filer_status,
              is_subscriber: thh_member&.is_subscriber || false
            }
          end
        end

        def construct_subscriber(subscriber)
          person = subscriber.person
          {
            member: {
              hbx_id: person.hbx_id,
              member_id: person.hbx_id,
              person_name: {
                first_name: person.name.first_name,
                last_name: person.name.last_name,
                middle_name: person.name.middle_name
              }
            },
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
              member: {
                hbx_id: person.hbx_id,
                member_id: person.hbx_id,
                person_name: {
                  first_name: person.name.first_name,
                  last_name: person.name.last_name,
                  middle_name: person.name.middle_name
                }
              },
              dob: dependent.dob,
              gender: dependent.gender,
              addresses: construct_addresses(person),
              emails: construct_emails(person)
            }
          end
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

        def any_thh_members_enrolled?(tax_household, enrs)
          all_enrolled_members = enrs.flat_map(&:subscriber) + enrs.flat_map(&:dependents)
          tax_household.tax_household_members.any? do |member|
            all_enrolled_members.map(&:person_id).uniq.include?(member.person_id)
          end
        end

        def construct_covered_individuals(enrollments, tax_household)
          covered_individuals = fetch_enrolled_thh_members(enrollments, tax_household)
          return [] if covered_individuals.compact.blank?

          covered_individuals.collect do |enrolled_member|
            insurance_policy = enrolled_member.aca_individuals_enrollment.insurance_policy
            glue_person = fetch_person_from_glue(enrolled_member.person)
            enrolled_member_end_date = insurance_policy.fetch_enrolled_member_end_date(enrolled_member)
            {
              coverage_start_on: enrolled_member.aca_individuals_enrollment.start_on,
              coverage_end_on: enrolled_member_end_date,
              person: construct_person_hash(enrolled_member.person, glue_person),
              relation_with_primary: enrolled_member.relation_with_primary,
              filer_status: fetch_tax_filer_status(tax_household, enrolled_member)
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

        def encrypt_ssn(ssn)
          result = AcaEntities::Operations::Encryption::Encrypt.new.call({ value: ssn })
          result.success? ? result.value! : ''
        end

        def valid_enrollment_tax_household?(enr_thh, tax_household)
          tax_filer_id = tax_household.primary&.person_id || tax_household.tax_household_members.first.person_id

          enr_thh_tax_filer_id =
            enr_thh.tax_household.primary&.person_id || enr_thh.tax_household.tax_household_members.first.person_id

          enr_thh_tax_filer_id == tax_filer_id
        end

        def covered_individuals_from_tax_household(covered_individuals, tax_household, enrollment)
          person_hbx_ids = tax_household.tax_household_members.flat_map(&:person).flat_map(&:hbx_id)
          enrolled_person_hbx_ids = [[enrollment.subscriber] + enrollment.dependents].flatten.map(&:person).map(&:hbx_id)
          covered_individuals.select do |individual|
            person_hbx_ids.include?(individual[:person][:hbx_id]) &&
              enrolled_person_hbx_ids.include?(individual[:person][:hbx_id])
          end
        end

        def update_covered_individuals_end_date(covered_individuals, enrollments_for_month, tax_household)
          enrollments_thhs = fetch_enrollments_tax_households(enrollments_for_month)
          valid_enr_thh = enrollments_thhs.select do |enr_thh|
                            valid_enrollment_tax_household?(enr_thh, tax_household)
                          end.sort_by(&:created_at)&.last
          enrollment = valid_enr_thh.enrollment
          valid_covered_individuals = covered_individuals_from_tax_household(covered_individuals,
                                                                             valid_enr_thh.tax_household, enrollment)
          valid_covered_individuals.map! do |individual|
            tax_household_for_individual =  @tax_households.detect do |thh|
              thh.primary_tax_filer_hbx_id == individual[:person][:hbx_id]
            end

            member_start_on = if tax_household_for_individual.present? && tax_household_for_individual != tax_household
                                fetch_member_start_on_for_non_primary(individual, tax_household_for_individual)
                              elsif tax_household_for_individual.present? && tax_household_for_individual == tax_household
                                fetch_member_start_on_for_primary(individual, tax_household_for_individual)
                              else
                                enrollment.insurance_policy.fetch_member_start_on(individual[:person][:hbx_id])
                              end

            individual[:coverage_start_on] = member_start_on
            individual[:coverage_end_on] = enrollment.enrollment_end_on
            individual
          end
        end

        def fetch_valid_enrollments_tax_households(enrollments, tax_household)
          enrollments_thhs = fetch_enrollments_tax_households(enrollments)
          enrollments_thhs.select { |enr_thh| valid_enrollment_tax_household?(enr_thh, tax_household) }
        end

        def fetch_member_start_on_for_primary(individual, tax_household_for_individual)
          valid_enr_thhs = fetch_valid_enrollments_tax_households(@enrollments, tax_household_for_individual)

          if valid_enr_thhs.present?
            valid_enr_thhs.flat_map(&:enrollment).map(&:start_on).min
          else
            individual[:coverage_start_on]
          end
        end

        def fetch_member_start_on_for_non_primary(individual, tax_household_for_individual)
          valid_enr_thhs = fetch_valid_enrollments_tax_households(@enrollments, tax_household_for_individual)
          enrollment = valid_enr_thhs.sort_by(&:created_at)&.last&.enrollment

          if enrollment.enrollment_end_on > individual[:coverage_start_on] &&
             enrollment.enrollment_end_on != enrollment.enrollment_end_on.end_of_year &&
             enrollment.enrollment_end_on.next_day < enrollment.insurance_policy_end_on
            enrollment.enrollment_end_on.next_day
          else
            individual[:coverage_start_on]
          end
        end

        def enrollments_tax_household_for_month_empty?(enrollments_for_month, tax_household)
          return false unless tax_household.is_aqhp

          enrollments_thhs = fetch_enrollments_tax_households(enrollments_for_month)
          enrollments_thhs.detect { |enr_thh| valid_enrollment_tax_household?(enr_thh, tax_household) }.blank?
        end

        def construct_annual_premiums(months_of_year)
          all_coverage_information = months_of_year.compact.collect { |m| m[:coverage_information] }

          result =
            %i[tax_credit total_premium slcsp_benchmark_premium].each_with_object({}) do |k, output|
              output[k] = all_coverage_information.sum { |hash| hash[k] }
            end

          all_coverage_information.collect { |hash| hash.deep_transform_values!(&:to_hash) }
          result.deep_transform_values(&:to_hash)
        end

        def construct_coverage_information(insurance_policy, covered_individuals, tax_household)
          (1..12).collect do |month|
            enrollments_for_month = insurance_policy.enrollments_for_month(month, insurance_policy.start_on.year)
            if insurance_policy.aasm_state == "canceled"
              {
                month: Date::MONTHNAMES[month],
                coverage_information: {
                  tax_credit: Money.new((BigDecimal("0.0") * 100).round, 'USD'),
                  total_premium: Money.new((BigDecimal("0.0") * 100).round, 'USD'),
                  slcsp_benchmark_premium: Money.new((BigDecimal("0.0") * 100).round, 'USD')
                }
              }
            else
              next if enrollments_for_month.blank?
              next unless any_thh_members_enrolled?(tax_household, enrollments_for_month)
              next if enrollments_tax_household_for_month_empty?(enrollments_for_month, tax_household)

              if tax_household.is_aqhp && covered_individuals.present?
                update_covered_individuals_end_date(covered_individuals, enrollments_for_month, tax_household)
              end

              thh_members = fetch_tax_household_members(enrollments_for_month, tax_household)
              pediatric_dental_pre = enrollments_for_month.first
                                       &.pediatric_dental_premium(enrollments_for_month, thh_members, month)
              pre_amt_tot = calculate_ehb_premium_for(insurance_policy, tax_household, enrollments_for_month, month)
              aptc_tax_credit = insurance_policy.applied_aptc_amount_for(enrollments_for_month, month, tax_household)

              slcsp = insurance_policy.fetch_slcsp_premium(enrollments_for_month, month, tax_household, aptc_tax_credit)
              total_premium = format('%.2f', (pre_amt_tot.to_f + pediatric_dental_pre))
              {
                month: Date::MONTHNAMES[month],
                coverage_information: {
                  tax_credit: Money.new((BigDecimal(aptc_tax_credit) * 100).round, 'USD'),
                  total_premium: Money.new((BigDecimal(total_premium) * 100).round, 'USD'),
                  slcsp_benchmark_premium: Money.new((BigDecimal(slcsp) * 100).round, 'USD')
                }
              }
            end
          end
        end

        def calculate_ehb_premium_for(insurance_policy, tax_household, enrollments_for_month, calendar_month)
          return format('%.2f', 0.0) if insurance_policy.term_for_np && insurance_policy.policy_end_on.month == calendar_month

          calender_month_begin = Date.new(insurance_policy.start_on.year, calendar_month, 1)
          calender_month_end = calender_month_begin.end_of_month
          end_of_year = insurance_policy.start_on.end_of_year
          calender_month_days = (calender_month_begin..calender_month_end).count
          enrolled_members_in_month = get_enrolled_members_by_tax_household_for(enrollments_for_month, tax_household)

          premium_amount =
            enrolled_members_in_month
            .sum do |enrolled_member|
              enrollment = enrolled_member.aca_individuals_enrollment
              premium_schedule = enrolled_member.premium_schedule

              member_start_on = [enrollment.start_on, calender_month_begin].max
              member_end_on = [enrollment.end_on || end_of_year, calender_month_end].min
              coverage_days = (member_start_on..member_end_on).count
              premium_rate =
                if enrolled_member.tobacco_use == 'Y'
                  premium_schedule.non_tobacco_use_premium
                else
                  premium_schedule.premium_amount
                end

              if calender_month_days == coverage_days
                premium_rate
              else
                (premium_rate.to_f / calender_month_days) * coverage_days
              end
            end
            .round(2)

          format('%.2f', (premium_amount * insurance_policy.insurance_product.ehb))
        end

        def get_enrolled_members_by_tax_household_for(enrollments_for_month, tax_household)
          enrs_thhs = fetch_enrollments_tax_households(enrollments_for_month)
          valid_enr_thh = if enrs_thhs.size > 1
                            enrs_thhs.select do |enr_thh|
                              valid_enrollment_tax_household?(enr_thh, tax_household) && enr_thh.tax_household.is_aqhp
                            end
                          else
                            enrs_thhs.to_a
                          end

          all_enrolled_members = [
            enrollments_for_month.flat_map(&:subscriber) + enrollments_for_month.flat_map(&:dependents)
          ].flatten

          enrolled_members = all_enrolled_members.select do |member|
            thh_primary_tax_filer_hbx_id = fetch_thh_primary_tax_filer_hbx_id_for_enrollment_member(member)
            thh_primary_tax_filer_hbx_id.present? ? tax_household.primary_tax_filer_hbx_id == thh_primary_tax_filer_hbx_id : true
          end

          thh_members = fetch_thh_members_from_enr_thhs(valid_enr_thh, tax_household)
          enrolled_members.select { |enr_member| thh_members.map(&:person_id).include?(enr_member.person_id) }
        end

        def fetch_thh_primary_tax_filer_hbx_id_for_enrollment_member(member)
          member.aca_individuals_enrollment.enrollments_tax_households.detect do |enr_thh|
            enr_thh.tax_household.tax_household_members.where(person_id: member.person_id).first.present? &&
              enr_thh.tax_household.is_aqhp
          end&.tax_household&.primary_tax_filer_hbx_id
        end

        def fetch_enrolled_enrollment_members_per_thh_for_month(enrollments_for_month, tax_household)
          enrs_thhs = fetch_enrollments_tax_households(enrollments_for_month)
          enrolled_members =
            [enrollments_for_month.flat_map(&:subscriber) + enrollments_for_month.flat_map(&:dependents)].flatten.uniq(
              &:person_id
            )
          thh_members = fetch_thh_members_from_enr_thhs(enrs_thhs, tax_household)

          enrolled_members.select { |enr_member| thh_members.map(&:person_id).include?(enr_member.person_id) }
        end

        def fetch_tax_household_members(enrollments, tax_household)
          enrs_thhs =
            ::InsurancePolicies::AcaIndividuals::EnrollmentsTaxHouseholds.where(
              :enrollment_id.in => enrollments.map(&:id)
            )
          thhs = ::InsurancePolicies::AcaIndividuals::TaxHousehold.where(:id.in => enrs_thhs.map(&:tax_household_id))

          thhs.select do |thh|
            thh.primary_tax_filer_hbx_id == tax_household.primary_tax_filer_hbx_id
          end.map(&:tax_household_members)&.flatten&.uniq(&:person_id)
        end

        def fetch_enrollments_tax_households(enrollments)
          ::InsurancePolicies::AcaIndividuals::EnrollmentsTaxHouseholds.where(
            :enrollment_id.in => enrollments.pluck(:id)
          )
        end

        # rubocop:disable Metrics/CyclomaticComplexity
        def fetch_thh_members_from_enr_thhs(enr_thhs, tax_household)
          thh_members_from_enr_thhs =
            enr_thhs.flat_map(&:tax_household).flat_map(&:tax_household_members).uniq(&:person_id)
          return thh_members_from_enr_thhs if enr_thhs.present? && !tax_household.is_aqhp
          return tax_household.tax_household_members unless tax_household.is_aqhp

          enr_thhs_for_month = enr_thhs.select do |enr_thh|
            enr_thh.tax_household.is_aqhp && valid_enrollment_tax_household?(enr_thh, tax_household)
          end

          enr_thhs_for_month&.flat_map(&:tax_household)&.flat_map(&:tax_household_members)&.uniq(&:person_id) ||
            thh_members_from_enr_thhs
        end

        # rubocop:enable Metrics/CyclomaticComplexity
        def fetch_enrolled_thh_members(enrollments, tax_household)
          enr_thhs = fetch_enrollments_tax_households(enrollments)
          all_enrolled_members =
            [enrollments.flat_map(&:subscriber) + enrollments.flat_map(&:dependents)].flatten.uniq(&:person_id)

          thh_members = fetch_thh_members_from_enr_thhs(enr_thhs, tax_household)
          all_enrolled_members.select { |member| thh_members.map(&:person_id).include?(member.person_id) }
        end

        def fetch_tax_filer_status(tax_household, enrollee)
          thh_member = tax_household.tax_household_members.detect { |member| member.person_id == enrollee.person_id }

          thh_member&.tax_filer_status || 'non_filer'
        end
      end
      # rubocop:enable Metrics/ClassLength
    end
  end
end
