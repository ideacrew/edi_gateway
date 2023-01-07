# frozen_string_literal: true

module InsurancePolicies
  module AcaIndividuals
    class IrsGroup
      include Mongoid::Document
      include Mongoid::Timestamps
      include DomainModels::Domainable

      has_many :aca_individual_insurance_policies,
               class_name: 'InsurancePolicies::AcaIndividuals::InsurancePolicy',
               inverse_of: :irs_group

      has_many :tax_household_groups, class_name: 'InsurancePolicies::AcaIndividuals::TaxHouseholdGroup',
                                      dependent: :destroy


      field :irs_group_id, type: String
      field :start_on, type: Date
      field :end_on, type: Date

      # indexes
      index({ irs_group_id: 1 })

      def active_tax_household_group(calendar_year)
        tax_household_groups.where(end_on: Date.new(calendar_year, 12, 31), assistance_year: calendar_year)&.first ||
          tax_household_groups.where(end_on: nil, assistance_year: calendar_year)&.first
      end

      def active_thhs_with_tax_filer(calendar_year)
        active_tax_household_group(calendar_year)&.tax_households&.select do |thh|
          thh if thh.tax_household_members.where(tax_filer_status: "tax_filer").present?
        end
      end

      def active_tax_households(calendar_year)
        result = active_thhs_with_tax_filer(calendar_year)
        if result.present?
          result.to_a
        elsif tax_household_groups.where(is_aqhp: false).present?
          [tax_household_groups.where(is_aqhp: false, assistance_year: calendar_year).first.tax_households.last]
        else
          [tax_household_groups.all.last.tax_households].flatten
        end
      end

      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/CyclomaticComplexity
      def active_thh_for_month(month, year)
        tax_household_groups.flat_map(&:tax_households).detect do |thh|
          next if thh.start_on == thh.end_on
          next if thh.tax_household_group.is_aqhp == false

          end_of_month = Date.new(year, month, 1).end_of_month
          next unless thh.start_on < end_of_month

          start_date = thh.start_on
          end_date = thh.end_on.present? ? thh.end_on.month : start_date.end_of_year
          coverage_end_month = end_date.month
          coverage_end_month = 12 if year != end_date.year
          (start_date.month..coverage_end_month).include?(month)
        end
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/CyclomaticComplexity
    end
  end
end

#
# InsurancePolicy.all.each do |policy|
#   irs_group = policy.irs_group
#   contract_holder = policy.insurance_agreement.contract_holder
#   tax_households = irs_group.active_tax_households(2022)
#   tax_households.each do |tax_household|
#     enrolled_members = pick_enrolled_mapping_tax_household_members(tax_household)
#
#       {
#         family_members: [contract_holder_information(contract_holder)],
#         households: {
#           hbx_enrollments: [policy_info, policy_product_info, policy_carrier_info, enrolled_members,
#                             coverage_information_for_policy]
#
#         }
#       }
#   end
# end
#
# # Family(Irs Group) (2 policies)
# #  Policy 1 (A, B,C) -  has 3 thh's
# #  policy 2 - has 1 thh
#
# # {
# #   family_members: [all_thhs_members(2 policies)];
# # households: {
# #   hbx_enrollments_p1_t1 -> ()
# # hbx_enrollment_p1_t2,
# #   hbx_enrollment_p1_t3,
# #   hbx_enrollment_p2_t1
# # hbx
# # }
# #
# # }
#
# InsurancePolicies::AcaIndividuals::IrsGroup.all.each do |irs_group|
#   insurance_policies = irs_group.aca_individual_insurance_policies
#   policies = insurance_policies.reject do |pol|
#     non_eligible_policy(pol)
#   end
#
#   thh_groups = irs_group.tax_household_groups
#   if thh_groups
#   uniq_thh_members = thh_groups.flat_map(&:tax_households).flat_map(&:tax_household_members).uniq(&:person_id)
#   payload = {
#     family_members: construct_family_members(uniq_thh_members),
#     households: construct_households(policies, irs_group)
#   }
#   pp payload
# rescue => e
#   puts "unablt ot generate for IRS group #{irs_group.irs_group_id}"
# end
#
# def construct_households(policies, irs_group)
#   [{
#      start_date: irs_group.start_on,
#      is_active: true,
#      hbx_enrollments: construct_enrollments(policies, irs_group)
#   }]
# end
#
# def construct_enrollments(policies, irs_group)
#   enrollment_hash = []
#   policies.each do |policy|
#     tax_households_per_year = irs_group.active_tax_households(policy.start_on.year)
#     tax_households_per_year.each do |tax_household|
#       enrolled_members = fetch_enrolled_enrollment_members_for_thh(policy, tax_household)
#       enrollment_hash << {
#         hbx_id: policy.policy_id,
#         effective_on: policy.start_on,
#         terminated_on: policy.end_on || policy.start_on.end_of_year,
#         aasm_state: policy.aasm_state,
#         market_place_kind: "individual",
#         enrollment_kind: "open_enrollment",
#         product_kind: policy.insurance_product.coverage_type,
#         hbx_enrollment_members: construct_enrollment_members(enrolled_members),
#         product_reference: construct_product_reference(policy),
#         issuer_profile_reference: construct_issuer_profile_hash(policy.insurance_product),
#         coverage_information: construct_coverage_information(policy, tax_household)
#       }
#     end
#   end
#   enrollment_hash
# end
#
# def construct_coverage_information(policy, tax_household)
#   (1..12).each_with_object({}) do |month, result|
#     enrolled_members_in_month = fetch_enrolled_enrollment_members_per_thh_for_month(policy, tax_household, month)
#     next if enrolled_members_in_month.empty?
#
#     slcsp, aptc, pre_amt_tot = policy.enrollments.first.fetch_npt_h36_prems(enrolled_members_in_month)
#     result[Date::MONTHNAMES[month]] = { premium: pre_amt_tot, slcsp: slcsp, apt_tax_credit: aptc}
#   end
# end
#
# def construct_product_reference(policy)
#   insurance_product = policy.insurance_product
#   {
#     hios_id: insurance_product.hios_plan_id,
#     name: insurance_product.name,
#     active_year: insurance_product.plan_year,
#     is_dental_only: false,
#     metal_level: insurance_product.metal_level,
#     benefit_market_kind: insurance_product.market_type,
#     product_kind:  insurance_product.coverage_type,
#     issuer_profile_reference: construct_issuer_profile_hash(insurance_product)
#   }
# end
#
# def construct_issuer_profile_hash(product)
#   insurance_provider = product.insurance_provider
#   {
#     name: insurance_provider.issuer_me_name,
#     hbx_id: insurance_provider.fein,
#     abbrev: insurance_provider.title
#   }
# end
#
# def construct_enrollment_members(enrolled_members)
#   enrolled_members.collect do |enr_member|
#     {
#       family_member_reference: { family_member_hbx_id: enr_member.person.hbx_id, ssn: enr_member.ssn,
#                                  dob: enr_member.dob },
#       coverage_start_on: enr_member.aca_individuals_enrollment.start_on,
#       coverage_end_on: enr_member.aca_individuals_enrollment.insurance_policy.policy_end_on,
#       eligibility_date: enr_member.aca_individuals_enrollment.start_on,
#       is_subscriber: enr_member.relation_with_primary == "self" ? true : false
#     }
#   end
# end
#
# def fetch_enrolled_enrollment_members_for_thh(policy, tax_household)
#   enrolled_members = [policy.enrollments.flat_map(&:subscriber) + policy.enrollments.flat_map(&:dependents)]
#                        .flatten.uniq(&:person_id)
#   tax_household_members = tax_household.tax_household_members
#
#   enrolled_members.select { |enr_member| tax_household_members.map(&:person_id).include?(enr_member.person_id) }
# end
#
# def fetch_enrolled_enrollment_members_per_thh_for_month(policy, tax_household, month)
#   enrollments_for_month = InsurancePolicies::AcaIndividuals::InsurancePolicy
#                             .enrollments_for_month(month, policy.start_on.year, [policy])
#
#   enrolled_members = [enrollments_for_month.flat_map(&:subscriber) + enrollments_for_month.flat_map(&:dependents)]
#                        .flatten.uniq(&:person_id)
#   tax_household_members = tax_household.tax_household_members
#
#   enrolled_members.select { |enr_member| tax_household_members.map(&:person_id).include?(enr_member.person_id) }
# end
#
# # Policy 1 -> A, B, C , A IN T1, B IN T2, C IN T3
# # POLICY 2 -> D,
#
# def construct_family_members(uniq_thh_members)
#   uniq_thh_members.collect do |thh_member|
#     people_person = thh_member.person
#     glue_person = fetch_person_from_glue(people_person)
#     {
#       is_primary_applicant: thh_member.is_subscriber,
#       relation_with_primary: thh_member.relation_with_primary,
#       person: construct_person_hash(glue_person)
#     }
#   end
# end
#
# def construct_person_hash(glue_person)
#   authority_member = glue_person.authority_member
#   {
#     hbx_id: glue_person.authority_member_id,
#     person_name: { first_name: glue_person.name_first, last_name: glue_person.name_last },
#     person_demographics: { gender: authority_member.gender,
#                            ssn: authority_member.ssn,
#                            dob: authority_member.dob },
#     person_health: {},
#     is_active: true,
#     addresses: construct_addresses(glue_person),
#     emails: construct_emails(glue_person)
#   }
# end
#
# def construct_addresses(glue_person)
#   glue_person.addresses.collect do |address|
#     {
#       kind: address.address_type,
#       address_1: address.address_1,
#       address_2: address.address_2,
#       address_3: address.address_3,
#       city_name: address.city,
#       county_name: address.county,
#       state_abbreviation: address.state,
#       zip_code: address.zip
#     }
#   end
# end
#
# def construct_emails(glue_person)
#   glue_person.emails.collect do |email|
#     {
#       kind: email.email_type,
#       address: email.email_address
#     }
#   end
# end
#
# def fetch_person_from_glue(people_person)
#   Person.where(authority_member_id: people_person.hbx_id).first
# end
#
# def non_eligible_policy(pol)
#   return true if pol.aasm_state == "canceled"
#   return true if pol.insurance_product.coverage_type == 'dental'
#   return true if pol.insurance_product.metal_level == "catastrophic"
#   return true if pol.carrier_policy_id.blank?
#
#
#   false
# end
