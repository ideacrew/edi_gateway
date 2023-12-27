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

      def enrollment_end_on
        end_on.present? ? end_on : insurance_policy.start_on.end_of_year
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

      # Fetch eligible enrollees based on tax household members.
      #
      # @param enrollments [Array<Enrollment>] The list of enrollments.
      # @param tax_household_members [Array<TaxHouseholdMember>] The list of tax household members.
      # @return [Array<Enrollee>] The eligible enrollees.
      def fetch_eligible_enrollees(enrollments, tax_household_members)
        all_enrolled_members = [enrollments.flat_map(&:subscriber) + enrollments.flat_map(&:dependents)].flatten.compact
        thh_mem_person_hbx_ids = tax_household_members.map(&:person).map(&:hbx_id)
        all_enrolled_members.select do |enrollee|
          thh_mem_person_hbx_ids.include?(enrollee.person.hbx_id)
        end
      end

      # Calculate the pediatric dental premium for a specific calendar month.
      #
      # @param enrollments_for_month [Array<Enrollment>] The list of enrollments for the month.
      # @param tax_household_members [Array<TaxHouseholdMember>] The list of tax household members.
      # @param calendar_month [Integer] The calendar month for which the premium is calculated.
      # @return [Float] The calculated pediatric dental premium for the specified month.
      def pediatric_dental_premium(enrollments_for_month, tax_household_members, calendar_month)
        return 0.0 if insurance_policy.term_for_np && insurance_policy.policy_end_on.month == calendar_month

        eligible_enrollees = fetch_eligible_enrollees(enrollments_for_month, tax_household_members)
        return 0.0 if eligible_enrollees.empty?

        ::IrsGroups::CalculateDentalPremiumForEnrolledChildren.new.call({ enrollments: enrollments_for_month,
                                                                          enrolled_people: eligible_enrollees,
                                                                          month: calendar_month }).value!.to_f
      end
      # rubocop:enable Metrics/AbcSize

      def enrolled_member_by_hbx_id(hbx_id)
        [[subscriber] + dependents].flatten.detect do |enrollee|
          enrollee.person.hbx_id == hbx_id
        end
      end

      # Determines if an enrollment is eligible.
      #
      # An eligible enrollment meets all of the following:
      # - The enrollment end date is after the individual's coverage start date
      # - The enrollment does not end on the last day of the year
      # - There is no gap between the enrollment end date and the next insurance policy date
      # - The next day of the enrollment end date is before the individual's coverage end date
      #
      # @param individual hash [Individual Hash] The individual hash
      # @return [Boolean] True if the enrollment meets eligibility criteria for the individual
      def is_enrollment_eligible?(individual)
        enrollment_end_on > individual[:coverage_start_on] &&
          enrollment_end_on != enrollment_end_on.end_of_year &&
          enrollment_end_on.next_day < insurance_policy_end_on &&
          enrollment_end_on.next_day < individual[:coverage_end_on]
      end
    end
  end
end
