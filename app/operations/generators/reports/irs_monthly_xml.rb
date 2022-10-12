#changes for health exchange id

module Generators::Reports  
  class IrsMonthlyXml
  # To generate irs yearly policies need to send a run time calendar_year params i.e. Generators::Reports::IrsMonthlyXml.new(irs_group, policies, calendar_year, max_month, folder_path) instead of sending hard coded year

    NS = { 
      "xmlns" => "urn:us:gov:treasury:irs:common",
      "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
      "xmlns:n1" => "urn:us:gov:treasury:irs:msg:monthlyexchangeperiodicdata"
    }

    attr_accessor :folder_path, :calendar_year, :irs_group, :max_month, :policies

    def initialize(irs_group, policies, calendar_year, max_month, folder_path)
      @irs_group = irs_group
      @policies = policies
      @calendar_year = calendar_year
      @max_month = max_month
      @folder_path = folder_path
    end

    def serialize
      File.open("#{@folder_path}/#{@irs_group.irs_group_id}.xml", 'w') do |file|
        file.write builder.to_xml(:indent => 2)
      end
    end

    def builder
      Nokogiri::XML::Builder.new do |xml|
        xml['n1'].HealthExchange(NS) do
          xml.SubmissionYr Date.today.year.to_s
          xml.SubmissionMonthNum max_month
          xml.ApplicableCoverageYr calendar_year
          xml.IndividualExchange do |xml|
            xml.HealthExchangeId "02.ME*.SBE.001.001"
            serialize_irs_group(xml)
          end
        end
      end
    end

    def serialize_irs_group(xml)
      xml.IRSHouseholdGrp do |xml|
        xml.IRSGroupIdentificationNum irs_group.irs_group_id
        serialize_taxhouseholds(xml)
        serialize_insurance_policies(xml)
      end
    end

    def serialize_taxhouseholds(xml)
      tax_household = irs_group.insurance_agreements.first.tax_households.where(end_date: nil).last
      xml.TaxHousehold do |xml|
        (1..max_month).each do |calendar_month|
          next if Policy.policies_for_month(calendar_month, calendar_year, policies).empty?
          serialize_taxhousehold_coverage(xml, tax_household, calendar_month)
        end
      end
    end

    def serialize_taxhousehold_coverage(xml, tax_household, calendar_month)
      xml.TaxHouseholdCoverage do |xml|
        xml.ApplicableCoverageMonthNum prepend_zeros(calendar_month.to_s, 2)
        xml.Household do |xml|
          serialize_household_members(xml, tax_household)
          Policy.policies_for_month(calendar_month, calendar_year, policies).each do |policy|
            serialize_associated_policy(xml, tax_household, calendar_month, policy)
          end
        end
      end
    end

    def serialize_household_members(xml, tax_household)
      serialize_tax_individual(xml, tax_household.primary, 'Primary')
      serialize_tax_individual(xml, tax_household.spouse, 'Spouse')
      tax_household.dependents.each do |dependent|
        serialize_tax_individual(xml, dependent, 'Dependent')
      end
    end

    def serialize_tax_individual(xml, tax_household_member, relation)
      individual = tax_household_member&.thm_individual
      return if individual.blank?

      xml.send("#{relation}Grp") do |xml|
        relation = 'DependentPerson' if relation == 'Dependent'          
        xml.send(relation) do |xml|
          auth_mem = individual.authority_member
          serialize_names(xml, individual)
          xml.SSN auth_mem.ssn unless auth_mem.ssn.blank?
          xml.BirthDt date_formatter(auth_mem.dob)
          serialize_address(xml, individual.addresses[0]) if relation == 'Primary'
        end
      end
    end

    def serialize_names(xml, individual)
      xml.CompletePersonName do |xml|
        xml.PersonFirstName individual.name_first
        xml.PersonMiddleName individual.name_middle
        xml.PersonLastName individual.name_last
        xml.SuffixName individual.name_sfx
      end
    end

    def serialize_address(xml, address)
      return if address.blank?

      xml.PersonAddressGrp do |xml|
        xml.USAddressGrp do |xml|
          xml.AddressLine1Txt address.address_1
          xml.AddressLine2Txt address.address_2
          xml.CityNm address.city.gsub(/[\.\,]/, '')
          xml.USStateCd address.state
          xml.USZIPCd address.zip.split('-')[0]
        end
      end
    end

    def serialize_associated_policy(xml, tax_household, calendar_month, policy)
      slcsp, aptc, pre_amt_tot = policy.fetch_npt_h36_prems(tax_household, calendar_month)
      xml.AssociatedPolicy do |xml|
        xml.QHPPolicyNum policy.eg_id
        xml.QHPIssuerEIN policy&.carrier&.fein
        xml.SLCSPAdjMonthlyPremiumAmt '%.2f'%slcsp
        xml.HouseholdAPTCAmt '%.2f'%aptc
        xml.TotalHsldMonthlyPremiumAmt '%.2f'%pre_amt_tot
      end
    end

    def serialize_insurance_policies(xml)
      tax_household = irs_group.insurance_agreements.first.tax_households.where(end_date: nil).last
      policies.each do |policy|
        xml.InsurancePolicy do |xml|
          serialize_insurance_coverages(xml, policy, tax_household)
        end
      end
    end

    def serialize_insurance_coverages(xml, policy, tax_household)
      (1..max_month).each do |calendar_month|
        next if Policy.policy_reported_month(calendar_month, calendar_year, policy).nil?
        slcsp, aptc, pre_amt_tot = policy.fetch_npt_h36_prems(tax_household, calendar_month)
        xml.InsuranceCoverage do |xml|
          xml.ApplicableCoverageMonthNum prepend_zeros(calendar_month.to_s, 2)
          xml.QHPPolicyNum policy.eg_id
          xml.QHPIssuerEIN policy.carrier.fein
          xml.IssuerNm policy.carrier.name
          xml.PolicyCoverageStartDt date_formatter(policy.policy_start)
          xml.PolicyCoverageEndDt date_formatter(policy.policy_end_on)
          xml.TotalQHPMonthlyPremiumAmt '%.2f'%pre_amt_tot
          xml.APTCPaymentAmt '%.2f'%aptc

          if policy.covered_enrollees_as_of(calendar_month, calendar_year).empty?
            raise "Missing enrollees #{policy.policy_id} #{calendar_month} #{calendar_year}"
          end

          policy.covered_enrollees_as_of(calendar_month, calendar_year).each do |enrollee|
            serialize_covered_individual(xml, enrollee)
          end
          xml.SLCSPMonthlyPremiumAmt '%.2f'%slcsp
        end
      end
    end

    def serialize_covered_individual(xml, enrollee)
      individual = enrollee&.person
      auth_mem = individual&.authority_member
      return if auth_mem.nil?

      xml.CoveredIndividual do |xml|
        xml.InsuredPerson do |xml|
          serialize_names(xml, individual)
          xml.SSN auth_mem.ssn unless auth_mem.ssn.blank?
          xml.BirthDt date_formatter(auth_mem.dob)
        end
        xml.CoverageStartDt date_formatter(enrollee.coverage_start)
        xml.CoverageEndDt date_formatter(enrollee.coverage_end_date)
      end
    end

    private

    def prepend_zeros(number, n)
      (n - number.size).times { number.prepend('0') }
      number
    end

    def date_formatter(date)
      return if date.nil?

      if date.is_a?(Date)
        date.strftime("%Y-%m-%d")
      else
        Date.strptime(date,'%m/%d/%Y').strftime("%Y-%m-%d")
      end
    end
  end
end