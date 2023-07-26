# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Generators
  module Reports
    # This class is used to generate the SBMI PBP XML file
    class SbmiXml
      include ActionView::Helpers::NumberHelper
      send(:include, Dry::Monads[:result, :do])

      def call(params = {})
        @sbmi_policy = params[:sbmi_policy]
        @folder_path = params[:folder_path]
        result = serialize

        Success(result)
      end

      def serialize
        File.write("#{@folder_path}/#{@sbmi_policy.record_control_number}.xml", builder.to_xml(:indent => 2))

        Success(true)
      end

      def builder
        Nokogiri::XML::Builder.new do |xml|
          xml.Policy do |policy_xml|
            serialize_policy(policy_xml)
          end
        end
      end

      def serialize_policy(xml)
        xml.RecordControlNumber @sbmi_policy.record_control_number
        xml.QHPId @sbmi_policy.qhp_id
        xml.ExchangeAssignedPolicyId @sbmi_policy.exchange_policy_id
        xml.ExchangeAssignedSubscriberId @sbmi_policy.exchange_subscriber_id
        xml.IssuerAssignedPolicyId @sbmi_policy.issuer_policy_id if @sbmi_policy.issuer_policy_id.present?
        xml.PolicyStartDate @sbmi_policy.coverage_start.strftime("%Y-%m-%d")
        xml.PolicyEndDate @sbmi_policy.coverage_end.strftime("%Y-%m-%d")
        xml.EffectuationIndicator @sbmi_policy.effectuation_status
        xml.InsuranceLineCode @sbmi_policy.insurance_line_code

        grouped_members = @sbmi_policy.coverage_household.group_by(&:exchange_assigned_memberId)

        grouped_members.each do |_member_id, covered_individuals|
          serialize_covered_individual(xml, covered_individuals)
        end

        @sbmi_policy.financial_loops.each do |financial_info|
          serialize_financial_information(xml, financial_info)
        end
      end

      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Lint/ShadowingOuterLocalVariable
      def serialize_covered_individual(covered_xml, grouped_individuals)
        individual = grouped_individuals[0]
        puts "missing zip #{@sbmi_policy.record_control_number}" if individual.postal_code.blank?

        grouped_individuals = grouped_individuals.sort_by(&:member_start_date).group_by(&:member_start_date).collect do |_k, v|
          v[0]
        end

        covered_xml.MemberInformation do |xml|
          xml.ExchangeAssignedMemberId individual.exchange_assigned_memberId
          xml.SubscriberIndicator individual.subscriber_indicator
          xml.MemberLastName chop_special_characters(individual.person_last_name)
          xml.MemberFirstName chop_special_characters(individual.person_first_name)
          xml.MemberMiddleName chop_special_characters(individual.person_middle_name)
          xml.NameSuffix chop_special_characters(individual.person_name_suffix)
          xml.BirthDate individual.birth_date&.strftime("%Y-%m-%d")
          xml.SocialSecurityNumber prepend_zeros(individual.social_security_number, 9)
          xml.PostalCode individual.postal_code
          xml.GenderCode individual.gender_code

          grouped_individuals.each do |individual|
            xml.MemberDates do |member_xml|
              member_xml.MemberStartDate individual.member_start_date.strftime("%Y-%m-%d")
              member_xml.MemberEndDate individual.member_end_date.strftime("%Y-%m-%d")
            end
          end
        end
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Lint/ShadowingOuterLocalVariable

      # rubocop:disable Metrics/AbcSize
      def serialize_financial_information(financial_xml, financial_info)
        financial_xml.FinancialInformation do |xml|
          xml.FinancialEffectiveStartDate financial_info.financial_effective_start_date&.strftime("%Y-%m-%d")
          xml.FinancialEffectiveEndDate financial_info.financial_effective_end_date&.strftime("%Y-%m-%d")
          xml.MonthlyTotalPremiumAmount(financial_info.monthly_premium_amount&.then { |amount| format("%.2f", amount) })
          xml.MonthlyTotalIndividualResponsibilityAmount(financial_info.monthly_responsible_amount&.then do |amount|
                                                           format("%.2f", amount)
                                                         end)
          xml.MonthlyAPTCAmount(financial_info.monthly_aptc_amount&.then { |amount| format("%.2f", amount) })
          if financial_info.csr_variant != '01'
            xml.MonthlyCSRAmount(financial_info.monthly_csr_amount&.then do |amount|
                                   format("%.2f", amount)
                                 end)
          end
          xml.CSRVariantId financial_info.csr_variant
          xml.RatingArea @sbmi_policy.rating_area
          if @sbmi_policy.effectuation_status == "Y"
            financial_info.prorated_amounts.each do |proration|
              serialize_prorations(xml, proration, financial_info.csr_variant)
            end
          end
        end
      end
      # rubocop:enable Metrics/AbcSize

      def serialize_prorations(prorated_xml, proration, csr_variant)
        prorated_xml.ProratedAmount do |xml|
          xml.PartialMonthEffectiveStartDate proration.partial_month_start_date.strftime("%Y-%m-%d")
          xml.PartialMonthEffectiveEndDate proration.partial_month_end_date.strftime("%Y-%m-%d")
          xml.PartialMonthPremiumAmount(proration.partial_month_premium&.then { |amount| format("%.2f", amount) })
          xml.PartialMonthAPTCAmount(proration.partial_month_aptc&.then { |amount| format("%.2f", amount) })
          xml.PartialMonthCSRAmount(proration.partial_month_csr&.then { |amount| format("%.2f", amount) }) if csr_variant != '01'
        end
      end

      private

      def prepend_zeros(number, size)
        return number if number.blank?

        (size - number.size).times { number.prepend('0') }
        number
      end

      def date_formatter(date)
        return if date.nil?

        Date.strptime(date, '%m/%d/%Y').strftime("%Y-%m-%d")
      end

      def chop_special_characters(name)
        return name if name.blank?

        name.gsub(/[!@#$%^&*()=_+|;:,<>?`]/, '').gsub(/[ñáéè]/, { "ñ" => "n", "á" => "a", "é" => "e", "è" => "e", "ì" => "i" })
      end
    end
  end
end
