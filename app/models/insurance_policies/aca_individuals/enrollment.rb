# frozen_string_literal: true

module InsurancePolicies
  module AcaIndividuals
    # An instance of insurance coverage under a single policy term for a group of enrolled members
    class Enrollment
      include Mongoid::Document
      include Mongoid::Timestamps
      include DomainModels::Domainable

      has_many :enrollments_tax_households,
               class_name: 'InsurancePolicies::AcaIndividuals::EnrollmentsTaxHouseholds',
               dependent: :destroy
      accepts_nested_attributes_for :enrollments_tax_households

      belongs_to :insurance_policy, class_name: 'InsurancePolicies::AcaIndividuals::InsurancePolicy', index: true

      embeds_one :subscriber, class_name: 'AcaIndividuals::EnrolledMember'
      embeds_many :dependents, class_name: 'AcaIndividuals::EnrolledMember'

      field :hbx_id, type: String
      field :aasm_state, type: String
      field :total_premium_amount, type: Money
      field :total_premium_adjustment_amount, type: Money
      field :total_responsible_premium_amount, type: Money
      field :effectuated_on, type: Date

      field :start_on, type: Date
      field :end_on, type: Date

      # indexes
      index({ "hbx_id" => 1 })
      index({ "aasm_state" => 1 })
      index({ "effectuated_on" => 1 })
      index({ "start_on" => 1 })
      index({ "end_on" => 1 })

      def coverage_end_on
        end_on.present? ? end_on : start_on.end_of_year
      end

      def tax_households
        ::InsurancePolicies::AcaIndividuals::EnrollmentsTaxHouseholds
          .where(:_id.in => self.enrollments_tax_households.pluck(:_id)).map(&:tax_household)
      end

      def enrolled_members_from_tax_household(tax_household)
        thh_mem_person_hbx_ids = tax_household.tax_household_members.map(&:person).map(&:hbx_id)
        [[subscriber] + dependents].flatten.select do |enrollee|
          thh_mem_person_hbx_ids.include?(enrollee.person.hbx_id)
        end
      end

      def insurance_policy_end_on
        insurance_policy.end_on.present? ? insurance_policy.end_on : insurance_policy.start_on.end_of_year
      end

      # rubocop:disable Metrics/AbcSize
      def pre_amt_tot_values(enrolled_thh_people, calendar_month)
        if insurance_policy.term_for_np && insurance_policy.policy_end_on.month == calendar_month
          format('%.2f', 0.0)
        else
          pre_amt_tot_month = enrolled_thh_people.map { |mem| mem.premium_schedule.premium_amount.to_f }.sum
          pre_amt_tot_month = (pre_amt_tot_month * insurance_policy.insurance_product.ehb).to_f.round(2)
          format('%.2f', pre_amt_tot_month)
        end
      end

      def fetch_eligible_enrollees(tax_household_members)
        thh_members = tax_household_members.reject { |member| member.is_medicaid_chip_eligible == true }
        thh_mem_person_hbx_ids = thh_members.map(&:person).map(&:hbx_id)
        [[subscriber] + dependents].flatten.select do |enrollee|
          thh_mem_person_hbx_ids.include?(enrollee.person.hbx_id)
        end
      end

      def pediatric_dental_premium(tax_household_members, calendar_month)
        return 0.0 if thh_members.empty?
        return 0.0 if insurance_policy.term_for_np && insurance_policy.policy_end_on.month == calendar_month

        eligible_enrollees = fetch_eligible_enrollees(tax_household_members)
        return 0.0 if eligible_enrollees.empty?

        ::IrsGroups::CalculateDentalPremiumForEnrolledChildren.new.call({ enrollment: self,
                                                                          enrolled_people: eligible_enrollees,
                                                                          month: calendar_month }).value!.to_f
      end
      # rubocop:enable Metrics/AbcSize

      def enrolled_member_by_hbx_id(hbx_id)
        [[subscriber] + dependents].flatten.detect do |enrollee|
          enrollee.person.hbx_id == hbx_id
        end
      end
    end
  end
end
