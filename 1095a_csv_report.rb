# frozen_string_literal: true

require "csv"
require "money"

offset = ARGV[0].to_i
limit = ARGV[1].to_i
tax_year = ARGV[2].to_i

fields = %w(IRS_GROUP_ID PRIMARY_PERSON_ID MARKETPLACE_ID POLICY_ID ISSUER_NAME RECIPIENT_NAME RECIPIENT_SSN
            RECIPIENT_DOB SPOUSE_NAME SPOUSE_SSN
            SPOUSE_DOB POLICY_START POLICY_END STREET_ADDRESS CITY
            STATE ZIPCODE COVERED_NAME_1 COVERED_SSN_1 COVERED_DOB_1 COVERED_START_1 COVERED_END_1 COVERED_NAME_2
            COVERED_SSN_2 COVERED_DOB_2 COVERED_START_2 COVERED_END_2 COVERED_NAME_3 COVERED_SSN_3 COVERED_DOB_3
            COVERED_START_3 COVERED_END_3 COVERED_NAME_4 COVERED_SSN_4 COVERED_DOB_4 COVERED_START_4 COVERED_END_4
            COVERED_NAME_5 COVERED_SSN_5 COVERED_DOB_5 COVERED_START_5 COVERED_END_5 COVERED_NAME_6 COVERED_SSN_6
            COVERED_DOB_6 COVERED_START_6 COVERED_END_6 COVERED_NAME_7 COVERED_SSN_7 COVERED_DOB_7 COVERED_START_7
            COVERED_END_7 COVERED_NAME_8 COVERED_SSN_8 COVERED_DOB_8 COVERED_START_8 COVERED_END_8 COVERED_NAME_9
            COVERED_SSN_9 COVERED_DOB_9 COVERED_START_9 COVERED_END_9 COVERED_NAME_10 COVERED_SSN_10 COVERED_DOB_10
            COVERED_START_10 COVERED_END_10 PREMIUM_1 SLCSP_1 APTC_1 PREMIUM_2 SLCSP_2 APTC_2
            PREMIUM_3 SLCSP_3 APTC_3 PREMIUM_4 SLCSP_4 APTC_4 PREMIUM_5 SLCSP_5 APTC_5 PREMIUM_6
            SLCSP_6 APTC_6 PREMIUM_7 SLCSP_7 APTC_7 PREMIUM_8 SLCSP_8 APTC_8 PREMIUM_9 SLCSP_9 APTC_9
            PREMIUM_10 SLCSP_10 APTC_10 PREMIUM_11 SLCSP_11 APTC_11 PREMIUM_12 SLCSP_12 APTC_12 PREMIUM_13 SLCSP_13
            APTC_13)

def query_criteria(tax_year, eligible_product_ids)
  { :start_on.gte => Date.new(tax_year, 1, 1),
    :start_on.lte => Date.new(tax_year, 12, 31),
    :aasm_state.nin => ["canceled"],
    :insurance_product_id.in => eligible_product_ids }
end

def non_catastrophic_product_ids
  InsurancePolicies::InsuranceProduct.where(:coverage_type => 'health',
                                            :metal_level.nin => ["catastrophic"]).pluck(:_id).flatten
end

def catastrophic_product_ids
  InsurancePolicies::InsuranceProduct.where(:coverage_type => 'health', :metal_level => "catastrophic")
                                     .pluck(:_id).flatten
end

def recipient(aptc_csr_tax_household, insurance_agreement, family)
  tax_filers = aptc_csr_tax_household.covered_individuals.select do |covered_individual|
    covered_individual.filer_status == 'tax_filer'
  end

  tax_filer =
    if tax_filers.count == 1
      tax_filers.first
    elsif tax_filers.count > 1
      tax_filers.detect { |tx_filer| tx_filer.relation_with_primary == 'self' }
    end

  return tax_filer if tax_filer.present?

  family.family_members.detect do |family_member|
    family_member.person.hbx_id == insurance_agreement.contract_holder.hbx_id
  end
end

def address
  if @recipient.person
    @recipient.person.addresses.detect { |address| address.kind == 'mailing' } || @recipient.person.addresses.first
  else
    @recipient.addresses.detect { |address| address.kind == 'mailing' } || @recipient.addresses.first
  end
end

def decrypt_ssn(encrypted_ssn)
  return "" if encrypted_ssn.blank?

  AcaEntities::Operations::Encryption::Decrypt.new.call({ value: encrypted_ssn }).value!
end

file_name = "ME-2022-1095A-FormData-#{offset}-#{DateTime.now.strftime('%Y%M%d')}-#{DateTime.now.strftime('%H%M%S')}.csv"
CSV.open(file_name.to_s, "w") do |csv|
  csv << fields
  logger = Logger.new("#{Rails.root}/log/me_2022_form_data_#{Date.today.strftime('%Y_%m_%d')}.log")
  query = query_criteria(tax_year, non_catastrophic_product_ids)
  policies = InsurancePolicies::AcaIndividuals::InsurancePolicy.where(query)
  irs_group_ids = policies&.pluck(:irs_group_id)&.uniq

  irs_groups = InsurancePolicies::AcaIndividuals::IrsGroup.all.where(:_id.in => irs_group_ids).order_by(:created_at.asc)

  irs_groups.offset(offset).limit(limit).each do |irs_group|
    irs_group = ::InsurancePolicies::AcaIndividuals::IrsGroup.includes(:tax_household_groups,
                                                                       aca_individual_insurance_policies: :enrollments)
                                                             .where(:irs_group_id => irs_group.irs_group_id).first
    if irs_group.blank?
      logger.info "Unable to fetch irs_group for #{irs_group.irs_group_id}"
      next
    end

    cv3_family_json = Tax1095a::Transformers::InsurancePolicies::Cv3Family.new.call({ tax_year: tax_year,
                                                                                      tax_form_type: "IVL_TAX",
                                                                                      irs_group_id: irs_group.irs_group_id })

    contract = AcaEntities::Contracts::Families::FamilyContract.new.call(JSON.parse(cv3_family_json.value!.to_json))
    family = AcaEntities::Families::Family.new(contract.to_h)

    _contract_holder = family.households.first.insurance_agreements.first.contract_holder
    valid_agreements = family.households.first.insurance_agreements

    valid_agreements.each do |agreement|
      insurance_provider = agreement.insurance_provider
      policies = agreement.insurance_policies

      if policies.empty?
        logger.info "no valid policies for #{irs_group.irs_group_id}"
        next
      end

      policies.each do |policy|
        tax_households = policy.aptc_csr_tax_households

        if tax_households.blank?
          logger.info "no tax_households for #{irs_group.irs_group_id}"
          next
        end

        tax_households.each do |tax_household|
          @recipient = recipient(tax_household, agreement, family)
          covered_individuals = tax_household.covered_individuals
          @spouse = tax_household.covered_individuals.detect do |covered_individual|
            covered_individual.relation_with_primary == 'spouse'
          end

          @has_aptc = tax_household.months_of_year.any? do |month|
            month.coverage_information && month.coverage_information.tax_credit.cents.positive?
          end
          @calender_year = agreement.plan_year.to_i
          months_of_year = tax_household.months_of_year
          annual_premiums = tax_household.annual_premiums

          covered_members_result = (0..9).collect do |index|
            individual = covered_individuals[index]
            if individual.present?
              person = individual.person
              ["#{person.person_name.first_name} #{person.person_name.last_name}",
               decrypt_ssn(person.person_demographics.encrypted_ssn), person.person_demographics.dob,
               individual.coverage_start_on, individual.coverage_end_on]
            else
              ["", "", "", "", ""]
            end
          end
          premium_values = (1..12).collect do |index|
            coverage_month = Date::MONTHNAMES[index]
            month_premiums = months_of_year.detect { |coverage| coverage.present? && coverage.month == coverage_month }
            if month_premiums.present?
              coverage_information = month_premiums.coverage_information
              [format("%.2f", Money.new(coverage_information.total_premium.cents).to_f),
               format("%.2f", Money.new(coverage_information.slcsp_benchmark_premium.cents).to_f),
               format("%.2f", Money.new(coverage_information.tax_credit.cents).to_f)]
            else
              ["", "", ""]
            end
          end
          csv << ([irs_group.irs_group_id,
                   @recipient.person.hbx_id,
                   "ME",
                   policy.policy_id,
                   insurance_provider.title,
                   "#{@recipient.person.person_name.first_name} #{@recipient.person.person_name.last_name}",
                   decrypt_ssn(@recipient&.person&.person_demographics&.encrypted_ssn),
                   @recipient&.person&.person_demographics&.dob,
                   @has_aptc ? "#{@spouse&.person&.person_name&.first_name} #{@spouse&.person&.person_name&.last_name}" : "",
                   @has_aptc ? decrypt_ssn(@spouse&.person&.person_demographics&.encrypted_ssn) : "",
                   @has_aptc ? @spouse&.person&.person_demographics&.dob : "",
                   policy.start_on,
                   policy.end_on,
                   address&.address_1,
                   address&.city,
                   address&.state,
                   address&.zip] + covered_members_result[0] +
            covered_members_result[1] + covered_members_result[2] +
            covered_members_result[3] + covered_members_result[4] + covered_members_result[5] +
            covered_members_result[6] + covered_members_result[7] + covered_members_result[8] +
            covered_members_result[9] +
            premium_values[0] + premium_values[1] + premium_values[2] + premium_values[3] + premium_values[4] +
            premium_values[5] + premium_values[6] + premium_values[7] + premium_values[8] + premium_values[9] +
            premium_values[10] + premium_values[11] +
            [format("%.2f", Money.new(annual_premiums.total_premium.cents).to_f),
             format("%.2f", Money.new(annual_premiums.slcsp_benchmark_premium.cents).to_f),
             format("%.2f", Money.new(annual_premiums.tax_credit.cents).to_f)])
        end
      end
    end
  rescue StandardError => e
    logger.info "Unable to populate data for irs_group #{irs_group.irs_group_id} due to #{e.backtrace}"
  end
end
