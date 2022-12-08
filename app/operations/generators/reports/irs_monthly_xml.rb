# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength

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
        insurance_agreement = irs_group.insurance_agreements.first
        irs_hhg_xml.TaxHousehold do |thh_xml|
          (1..max_month).each do |calendar_month|
            tax_household = insurance_agreement.covered_month_tax_household(calendar_year, calendar_month)
            next if Policy.policies_for_month(calendar_month, calendar_year, policies).empty?

            serialize_taxhousehold_coverage(thh_xml, tax_household, calendar_month)
          end
        end
      end

      def thh_to_pick(tax_household, calendar_month)
        aptc_to_pick = []
        Policy.policies_for_month(calendar_month, calendar_year, policies).each do |policy|
          _slcsp, aptc, _pre_amt_tot = policy.fetch_npt_h36_prems(tax_household, calendar_month)
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
              Policy.policies_for_month(calendar_month, calendar_year, policies).each do |policy|
                serialize_associated_policy(hh_xml, tax_household, calendar_month, policy)
              end
            end
          else
            thhc_xml.OtherRelevantAdult do |hh_xml|
              individual = fetch_thh_primary_person(tax_household)
              next if individual.blank?

              auth_mem = individual.authority_member
              serialize_names(hh_xml, individual)
              hh_xml.SSN auth_mem.ssn unless auth_mem.ssn.blank?
              hh_xml.BirthDt date_formatter(auth_mem.dob)
              serialize_address(hh_xml, individual.addresses[0])
            end
          end
        end
      end

      def fetch_thh_primary_person(tax_household)
        contract_holder = irs_group.insurance_agreements.first.contract_holder
        aqhp_primary = tax_household.primary
        if aqhp_primary.present?
          @logger.info("IrsGroup: #{irs_group.irs_group_id}, using aqhp_primary: #{aqhp_primary.person_hbx_id}")
          aqhp_primary.thm_individual
        else
          @logger.info("IrsGroup: #{irs_group.irs_group_id}, using uqhp_primary: #{contract_holder&.hbx_member_id}")
          contract_holder&.primary_person
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
        individual = tax_household_member&.thm_individual
        return if individual.blank?

        hh_xml.send("#{relation}Grp") do |rel_grp_xml|
          relation = 'DependentPerson' if relation == 'Dependent'
          rel_grp_xml.send(relation) do |person_xml|
            auth_mem = individual.authority_member
            serialize_names(person_xml, individual)
            person_xml.SSN auth_mem.ssn unless auth_mem.ssn.blank?
            person_xml.BirthDt date_formatter(auth_mem.dob)
            serialize_address(person_xml, individual.addresses[0]) if relation == 'Primary'
          end
        end
      end

      def serialize_names(person_xml, individual)
        person_xml.CompletePersonName do |xml|
          xml.PersonFirstName individual.name_first
          xml.PersonMiddleName individual.name_middle
          xml.PersonLastName individual.name_last
          xml.SuffixName individual.name_sfx
        end
      end

      def serialize_address(person_xml, address)
        return if address.blank?

        person_xml.PersonAddressGrp do |pag_xml|
          pag_xml.USAddressGrp do |xml|
            xml.AddressLine1Txt address.address_1
            xml.AddressLine2Txt address.address_2
            xml.CityNm address.city.gsub(/[.,]/, '')
            xml.USStateCd address.state
            xml.USZIPCd address.zip.split('-')[0]
          end
        end
      end

      def serialize_associated_policy(hh_xml, tax_household, calendar_month, policy)
        slcsp, aptc, pre_amt_tot = policy.fetch_npt_h36_prems(tax_household, calendar_month)
        hh_xml.AssociatedPolicy do |xml|
          xml.QHPPolicyNum policy.eg_id
          xml.QHPIssuerEIN policy&.carrier&.fein
          xml.SLCSPAdjMonthlyPremiumAmt slcsp
          xml.HouseholdAPTCAmt aptc
          xml.TotalHsldMonthlyPremiumAmt pre_amt_tot
        end
      end

      def serialize_insurance_policies(irs_hhg_xml)
        insurance_agreement = irs_group.insurance_agreements.first
        policies.each do |policy|
          irs_hhg_xml.InsurancePolicy do |insured_pol_xml|
            serialize_insurance_coverages(insured_pol_xml, policy, insurance_agreement)
          end
        end
      end

      def serialize_insurance_coverages(insured_pol_xml, policy, insurance_agreement)
        (1..max_month).each do |calendar_month|
          next if Policy.policy_reported_month(calendar_month, calendar_year, policy).nil?

          tax_household = insurance_agreement.covered_month_tax_household(calendar_year, calendar_month)
          slcsp, aptc, pre_amt_tot = policy.fetch_npt_h36_prems(tax_household, calendar_month)
          insured_pol_xml.InsuranceCoverage do |insured_cov_xml|
            insured_cov_xml.ApplicableCoverageMonthNum prepend_zeros(calendar_month.to_s, 2)
            insured_cov_xml.QHPPolicyNum policy.eg_id
            insured_cov_xml.QHPIssuerEIN policy.carrier.fein
            insured_cov_xml.IssuerNm policy.carrier.issuer_me_name
            insured_cov_xml.PolicyCoverageStartDt date_formatter(policy.policy_start)
            insured_cov_xml.PolicyCoverageEndDt date_formatter(policy.policy_end_on)
            insured_cov_xml.TotalQHPMonthlyPremiumAmt pre_amt_tot
            insured_cov_xml.APTCPaymentAmt aptc

            if policy.covered_enrollees_as_of(calendar_month, calendar_year).empty?
              raise "Missing enrollees #{policy.policy_id} #{calendar_month} #{calendar_year}"
            end

            policy.covered_enrollees_as_of(calendar_month, calendar_year).each do |enrollee|
              serialize_covered_individual(insured_cov_xml, enrollee)
            end
            (insured_cov_xml.SLCSPMonthlyPremiumAmt slcsp) unless thh_to_pick(tax_household, calendar_month)
          end
        end
      end

      def serialize_covered_individual(insured_cov_xml, enrollee)
        individual = enrollee&.person
        auth_mem = individual&.authority_member
        return if auth_mem.nil?

        insured_cov_xml.CoveredIndividual do |cov_ind_xml|
          cov_ind_xml.InsuredPerson do |person_xml|
            serialize_names(person_xml, individual)
            person_xml.SSN auth_mem.ssn unless auth_mem.ssn.blank?
            person_xml.BirthDt date_formatter(auth_mem.dob)
          end
          cov_ind_xml.CoverageStartDt date_formatter(enrollee.coverage_start)
          cov_ind_xml.CoverageEndDt date_formatter(enrollee.coverage_end_date)
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
