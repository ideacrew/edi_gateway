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

      belongs_to :insurance_policy, class_name: 'InsurancePolicies::AcaIndividuals::InsurancePolicy'

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

      def coverage_end_on
        end_on.present? ? end_on : start_on.end_of_year
      end

      def tax_households
        InsurancePolicies::AcaIndividuals::EnrollmentsTaxHouseholds.in(
          id: enrollments_tax_households.pluck(:tax_household_id)
        )
      end

      def enrolled_members_from_tax_household(tax_household)
        thh_mem_person_hbx_ids = tax_household.tax_household_members.map(&:person).map(&:hbx_id)
        [[subscriber] + dependents].flatten.select do |enrollee|
          thh_mem_person_hbx_ids.include?(enrollee.person.hbx_id)
        end
      end

      def fetch_npt_h36_prems(enrolled_thh_people, calendar_month)
        slcsp, pre_amt_tot_month = slcsp_pre_amt_tot_values(calendar_month, enrolled_thh_people)
        aptc = total_premium_adjustment_amount || 0.0
        [format('%.2f', slcsp), format('%.2f', aptc), format('%.2f', pre_amt_tot_month)]
      end

      def insurance_policy_end_on
        insurance_policy.end_on.present? ? insurance_policy.end_on : insurance_policy.start_on.end_of_year
      end

      # rubocop:disable Metrics/AbcSize
      def slcsp_pre_amt_tot_values(calendar_month, enrolled_thh_people)
        policy_end_on = insurance_policy_end_on
        return [0.0, 0.0] if policy_end_on.month == calendar_month

        slcsp = enrolled_thh_people.map { |mem| mem.premium_schedule.benchmark_ehb_premium_amount.to_f }.sum
        pre_amt_tot_month = enrolled_thh_people.map { |mem| mem.premium_schedule.premium_amount.to_f }.sum
        pre_amt_tot_month = (pre_amt_tot_month * insurance_policy.insurance_product.ehb).to_f.round(2)
        [slcsp, pre_amt_tot_month]
      end
      # rubocop:enable Metrics/AbcSize
    end
  end
end
