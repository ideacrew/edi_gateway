# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/PerceivedComplexity

module Generators
  module Reports
    # To generate irs yearly policies need to send a run time calendar_year params
    # Generators::Reports::IrsMonthlyXml.new(irs_group, policies, calendar_year, max_month, folder_path)
    class IrsMonthlyXml
      NS = {
        "xmlns" => "urn:us:gov:treasury:irs:common",
        "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
        "xmlns:n1" => "urn:us:gov:treasury:irs:msg:monthlyexchangeperiodicdata"
      }.freeze

      attr_accessor :folder_path, :calendar_year, :irs_group, :max_month, :policies

      def initialize(irs_group, policies, calendar_year, max_month, folder_path)
        @irs_group = irs_group
        @policies = policies
        @calendar_year = calendar_year
        @max_month = max_month
        @folder_path = folder_path
        @logger = Logger.new("#{Rails.root}/log/h36_OtherRelevantAdult_primary_person.log")
      end

      def serialize
        File.write("#{@folder_path}/#{@irs_group.irs_group_id}.xml", builder.to_xml(:indent => 2))
      end

      def builder
        Nokogiri::XML::Builder.new do |xml|
          xml['n1'].HealthExchange(NS) do
            xml.SubmissionYr Date.today.year.to_s
            xml.SubmissionMonthNum max_month == 12 ? 1 : (max_month + 1)
            xml.ApplicableCoverageYr calendar_year
            xml.IndividualExchange do |ind_xml|
              ind_xml.HealthExchangeId "02.ME*.SBE.001.001"
              serialize_irs_group(ind_xml)
            end
          end
        end
      end

      def serialize_irs_group(ind_xml)
        ind_xml.IRSHouseholdGrp do |irs_hhg_xml|
          irs_hhg_xml.IRSGroupIdentificationNum irs_group.irs_group_id
          serialize_taxhouseholds(irs_hhg_xml)
          serialize_insurance_policies(irs_hhg_xml)
        end
      end

      def serialize_taxhouseholds(irs_hhg_xml)
        tax_households = irs_group.irs_households_for_duration(calendar_year, max_month, policies).sort_by(&:start_on)
        tax_households.each do |tax_household|
          irs_hhg_xml.TaxHousehold do |thh_xml|
            (1..max_month).each do |calendar_month|
              policies_for_month = ::InsurancePolicies::AcaIndividuals::InsurancePolicy
                                   .enrollments_for_month(calendar_month, calendar_year, policies)
              any_aptc_applied_policies = policies_for_month.any? do |enr|
                enr.total_premium_adjustment_amount.to_f > 0.0
              end
              result = if tax_household.is_aqhp == false || !any_aptc_applied_policies
                         policies_for_month
                       else
                         thh_enrollments = ::InsurancePolicies::AcaIndividuals::EnrollmentsTaxHouseholds
                                           .where(tax_household_id: tax_household.id)
                         policies_for_month.map(&:hbx_id) & thh_enrollments.map(&:enrollment).map(&:hbx_id)
                       end
              next if result.blank?

              serialize_taxhousehold_coverage(thh_xml, tax_household, calendar_month)
            end
          end
        end
      end

      def thh_to_pick(tax_household, calendar_month)
        aptc_to_pick = []
        enrs_for_month = ::InsurancePolicies::AcaIndividuals::InsurancePolicy
                         .enrollments_for_month(calendar_month, calendar_year, policies)
        enrs_for_month.each do |enrollment|
          thh_enrolled_members = enrollment.enrolled_members_from_tax_household(tax_household)
          _slcsp, aptc, _pre_amt_tot = enrollment.fetch_npt_h36_prems(thh_enrolled_members, calendar_month)
          aptc_to_pick << aptc.to_f
        end

        aptc_to_pick.any?(&:positive?)
      end

      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/MethodLength

      def serialize_taxhousehold_coverage(thh_xml, tax_household, calendar_month)
        thh_xml.TaxHouseholdCoverage do |thhc_xml|
          thhc_xml.ApplicableCoverageMonthNum prepend_zeros(calendar_month.to_s, 2)
          if thh_to_pick(tax_household, calendar_month)
            thhc_xml.Household do |hh_xml|
              serialize_household_members(hh_xml, tax_household)
              enrs_for_month = ::InsurancePolicies::AcaIndividuals::InsurancePolicy
                               .enrollments_for_month(calendar_month, calendar_year, policies)
              enrs_for_month.each do |enrollment|
                serialize_associated_policy(hh_xml, tax_household, calendar_month, enrollment)
              end
            end
          else
            thhc_xml.OtherRelevantAdult do |hh_xml|
              contract_holder = irs_group.aca_individual_insurance_policies.last.insurance_agreement.contract_holder
              next if contract_holder.blank?

              serialize_names(hh_xml, contract_holder)
              glue_person = Person.where(authority_member_id: contract_holder.hbx_id).first.authority_member
              hh_xml.SSN glue_person.ssn unless glue_person.ssn.blank?
              hh_xml.BirthDt date_formatter(glue_person.dob)
              serialize_address(hh_xml, contract_holder.addresses[0])
            end
          end
        end
      end

      def serialize_household_members(hh_xml, tax_household)
        serialize_tax_individual(hh_xml, tax_household.primary, 'Primary')
        serialize_tax_individual(hh_xml, tax_household.spouse, 'Spouse')
        tax_household.dependents.each do |dependent|
          serialize_tax_individual(hh_xml, dependent, 'Dependent')
        end
      end

      def serialize_tax_individual(hh_xml, tax_household_member, relation)
        return if tax_household_member.blank?

        person = tax_household_member&.person
        glue_person = Person.where(authority_member_id: person.hbx_id).first.authority_member
        return if glue_person.blank?

        hh_xml.send("#{relation}Grp") do |rel_grp_xml|
          relation = 'DependentPerson' if relation == 'Dependent'
          rel_grp_xml.send(relation) do |person_xml|
            serialize_names(person_xml, person)
            person_xml.SSN glue_person.ssn unless glue_person.ssn.blank?
            person_xml.BirthDt date_formatter(glue_person.dob)
            serialize_address(person_xml, person.addresses[0]) if relation == 'Primary'
          end
        end
      end

      def serialize_names(person_xml, individual)
        person_xml.CompletePersonName do |xml|
          xml.PersonFirstName individual.name.first_name
          xml.PersonMiddleName individual.name.middle_name
          xml.PersonLastName individual.name.last_name
          xml.SuffixName individual.name.name_sfx
        end
      end

      def serialize_address(person_xml, address)
        return if address.blank?

        person_xml.PersonAddressGrp do |pag_xml|
          pag_xml.USAddressGrp do |xml|
            xml.AddressLine1Txt address.address_1
            xml.AddressLine2Txt address.address_2
            xml.CityNm address.city_name.gsub(/[.,]/, '')
            xml.USStateCd address.state_abbreviation
            xml.USZIPCd address.zip_code.split('-')[0]
          end
        end
      end

      def serialize_associated_policy(hh_xml, tax_household, calendar_month, enrollment)
        thh_enrolled_members = enrollment.enrolled_members_from_tax_household(tax_household)
        slcsp, aptc, pre_amt_tot = enrollment.fetch_npt_h36_prems(thh_enrolled_members, calendar_month)
        pediatric_dental_pre = enrollment.pediatric_dental_premium(tax_household.tax_household_members,
                                                                       calendar_month)
        total_premium = pre_amt_tot.to_f + pediatric_dental_pre
        hh_xml.AssociatedPolicy do |xml|
          xml.QHPPolicyNum enrollment.insurance_policy.policy_id
          xml.QHPIssuerEIN enrollment&.insurance_policy&.insurance_product&.insurance_provider&.fein
          xml.SLCSPAdjMonthlyPremiumAmt slcsp
          xml.HouseholdAPTCAmt aptc
          xml.TotalHsldMonthlyPremiumAmt total_premium.to_s
        end
      end

      def serialize_insurance_policies(irs_hhg_xml)
        policies.each do |policy|
          irs_hhg_xml.InsurancePolicy do |insured_pol_xml|
            serialize_insurance_coverages(insured_pol_xml, policy)
          end
        end
      end

      def fetch_tax_household_members(enrollments)
        enrs_thhs = ::InsurancePolicies::AcaIndividuals::EnrollmentsTaxHouseholds.where(:"enrollment_id".in =>
                                                                                          enrollments.map(&:id))
        thhs = ::InsurancePolicies::AcaIndividuals::TaxHousehold.where(:"id".in => enrs_thhs.map(&:tax_household_id))

        thhs&.map(&:tax_household_members).flatten.uniq(&:person_id)
      end

      def serialize_insurance_coverages(insured_pol_xml, policy)
        (1..max_month).each do |calendar_month|
          enrollments = policy.enrollments_for_month(calendar_month, calendar_year)
          next if enrollments.blank?

          sorted_enrollments = enrollments.sort_by(&:start_on)
          thh_members = fetch_tax_household_members(sorted_enrollments)
          policy = sorted_enrollments.first.insurance_policy
          insured_pol_xml.InsuranceCoverage do |insured_cov_xml|
            enrolled_members_for_month = [[sorted_enrollments.map(&:subscriber)] +
              sorted_enrollments.map(&:dependents)].flatten.uniq(&:person_id)
            slcsp, aptc, pre_amt_tot = sorted_enrollments.first.fetch_npt_h36_prems(enrolled_members_for_month,
                                                                                    calendar_month)
            pediatric_dental_pre = sorted_enrollments.first.pediatric_dental_premium(thh_members,
                                                                                         calendar_month)
            total_premium = pre_amt_tot.to_f + pediatric_dental_pre
            insured_cov_xml.ApplicableCoverageMonthNum prepend_zeros(calendar_month.to_s, 2)
            insured_cov_xml.QHPPolicyNum policy.policy_id
            insured_cov_xml.QHPIssuerEIN policy.insurance_product.insurance_provider.fein
            insured_cov_xml.IssuerNm policy.insurance_product.insurance_provider.issuer_me_name
            insured_cov_xml.PolicyCoverageStartDt date_formatter(policy.start_on)
            insured_cov_xml.PolicyCoverageEndDt date_formatter(policy.policy_end_on)
            insured_cov_xml.TotalQHPMonthlyPremiumAmt total_premium.to_s
            insured_cov_xml.APTCPaymentAmt aptc

            sorted_enrollments.each do |enrollment|
              enrolled_members_for_month = [[enrollment.subscriber] + enrollment.dependents].flatten

              if enrolled_members_for_month.empty?
                raise "Missing enrollees #{policy.policy_id} #{calendar_month} #{calendar_year}"
              end

              enrolled_members_for_month.each do |enrollee|
                serialize_covered_individual(insured_cov_xml, enrollee)
              end
            end
            (insured_cov_xml.SLCSPMonthlyPremiumAmt slcsp) if sorted_enrollments.first.total_premium_adjustment_amount.to_f > 0.0
          end
        end
      end

      def serialize_covered_individual(insured_cov_xml, enrollee)
        individual = enrollee&.person
        return if individual.nil?

        insured_cov_xml.CoveredIndividual do |cov_ind_xml|
          cov_ind_xml.InsuredPerson do |person_xml|
            serialize_names(person_xml, individual)
            person_xml.SSN enrollee.ssn unless enrollee.ssn.blank?
            person_xml.BirthDt date_formatter(enrollee.dob)
          end
          cov_ind_xml.CoverageStartDt date_formatter(enrollee.aca_individuals_enrollment.start_on)
          cov_ind_xml.CoverageEndDt date_formatter(enrollee.aca_individuals_enrollment.coverage_end_on)
        end
      end

      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/MethodLength

      private

      def prepend_zeros(number, value)
        (value - number.size).times { number.prepend('0') }
        number
      end

      def date_formatter(date)
        return if date.nil?

        if date.is_a?(Date)
          date.strftime("%Y-%m-%d")
        else
          Date.strptime(date, '%m/%d/%Y').strftime("%Y-%m-%d")
        end
      end
    end
  end
end

# rubocop:enable Metrics/ClassLength
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/CyclomaticComplexity
# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/PerceivedComplexity
