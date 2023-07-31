# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'ostruct'

module Generators
  module Reports
    # This class is used to build a SbmiPolicy entity and generate PBP reports
    class SbmiPolicyBuilder
      send(:include, Dry::Monads[:result, :do])
      include MoneyMath

      def call(params = {})
        params = yield validate(params)
        @policy = params[:policy]
        policy_information = yield process
        validated_policy_information = yield validate_policy_information(policy_information)
        policy_entity = yield construct_policy_entity(validated_policy_information)

        Success(policy_entity)
      end

      private

      def validate(params)
        return Failure("policy is not present") unless params[:policy].present?

        Success(params)
      end

      def process
        Success(construct_policy_information)
      end

      def validate_policy_information(policy_information)
        result = AcaEntities::Cms::Pbp::Contracts::SbmiPolicyContract.new.call(policy_information)

        result.success? ? Success(result.to_h) : Failure("Invalid policy information: #{result.errors.to_h}")
      end

      def construct_policy_entity(policy_information)
        Success(AcaEntities::Cms::Pbp::SbmiPolicy.new(policy_information))
      end

      def construct_policy_information
        params = {
          record_control_number: @policy.id.to_s,
          qhp_id: @policy.plan.hios_plan_id.split('-').first,
          rating_area: @policy.rating_area,
          exchange_policy_id: @policy.eg_id,
          exchange_subscriber_id: @policy.subscriber.m_id,
          coverage_start: @policy.policy_start,
          coverage_end: @policy.policy_end_on,
          effectuation_status: fetch_effectuation_status,
          insurance_line_code: (@policy.plan.coverage_type =~ /health/i ? 'HLT' : 'DEN'),
          coverage_household: construct_coverage_household,
          financial_loops: construct_financial_information_loops
        }

        params[:issuer_policy_id] = @policy.subscriber.cp_id if @policy.subscriber.cp_id.present?
        params
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      def construct_coverage_household
        if @policy.canceled?
          if @policy.enrollees.any? { |e| !e.canceled? }
            raise "Canceled policy(#{policy.id}) has enrollee with improper start and end dates"
          end

          uniq_enrollees = @policy.enrollees.group_by(&:person).collect { |_k, v| v[0] }
          uniq_enrollees.map { |enrollee| construct_covered_individual(enrollee, (enrollee.subscriber? ? 'Y' : 'N')) }
        else
          enrollees = @policy.enrollees.reject(&:canceled?)
          enrollees.map { |enrollee| construct_covered_individual(enrollee, (enrollee.subscriber? ? 'Y' : 'N')) }
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      def construct_financial_information_loops
        financial_information_loops.map do |financial_dates|
          construct_financial_information(financial_dates)
        end
      end

      # rubocop:disable Lint/DuplicateBranch
      def fetch_effectuation_status
        if @policy.canceled?
          'N'
        elsif @policy.aasm_state == 'resubmitted'
          'Y'
        elsif @policy.subscriber.coverage_start > Date.new(2020, 12, 31)
          effectuated?(@policy) ? 'Y' : 'N'
        else
          'Y'
        end
      end
      # rubocop:enable Lint/DuplicateBranch

      def effectuated?(policy)
        policy&.subscriber&.cp_id&.present?
      end

      def construct_covered_individual(enrollee, is_subscriber)
        if enrollee.is_a?(Person)
          @coverage_start = @policy.policy_start
          @coverage_end = @policy.policy_end_on
          person = enrollee
        else
          person = enrollee.person
        end

        member = person.authority_member

        @subscriber_zipcode = postal_code(person) if is_subscriber == "Y"

        raise "Zip code missing!!" if @subscriber_zipcode.blank?

        {
          exchange_assigned_memberId: member.hbx_member_id,
          subscriber_indicator: is_subscriber,
          person_last_name: person.name_last,
          person_first_name: person.name_first,
          person_middle_name: person.name_middle,
          person_name_suffix: person.name_sfx,
          birth_date: member.dob,
          social_security_number: member.ssn,
          gender_code: fetch_gender(member),
          postal_code: (postal_code(person) || @subscriber_zipcode),
          member_start_date: @coverage_start || enrollee.coverage_start,
          member_end_date: @coverage_end || enrollee.coverage_end_date
        }
      end

      def fetch_gender(member)
        if member.gender == "male"
          'M'
        else
          (member.gender == "female" ? 'F' : 'U')
        end
      end

      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/MethodLength
      def construct_financial_information(financial_dates)
        total_premium = @policy.reported_pre_amt_tot_on(financial_dates[0])
        applied_aptc = @policy.reported_aptc_on(financial_dates[0])
        responsible_amount = @policy.reported_tot_res_amt_on(financial_dates[0])

        financial_info = {
          financial_effective_start_date: financial_dates[0],
          financial_effective_end_date: financial_dates[1],
          monthly_premium_amount: total_premium.to_f,
          monthly_responsible_amount: responsible_amount.to_f,
          monthly_aptc_amount: applied_aptc.to_f,
          monthly_csr_amount: 0.0.to_f,
          csr_variant: csr_variant
        }

        if mid_month_start_date?(financial_dates) && mid_month_end_date?(financial_dates)
          if financial_dates[0].month == financial_dates[1].month
            start_date = (financial_dates[1].day.to_f - financial_dates[0].day.to_f + 1.0)
            end_date = financial_dates[0].end_of_month.day
            multiplying_factor = (start_date / end_date)
            prorated_amounts_hash = {
              partial_month_premium: as_dollars(multiplying_factor * total_premium).to_f,
              partial_month_aptc: as_dollars(multiplying_factor * applied_aptc).to_f,
              partial_month_start_date: financial_dates[0],
              partial_month_end_date: financial_dates[1]
            }
            financial_info.merge!(prorated_amounts: [prorated_amounts_hash])
          else
            mid_month_start_hash = mid_month_start_prorated_amount(financial_dates[0], total_premium, applied_aptc)
            mid_month_end_hash = mid_month_end_prorated_amount(financial_dates[1], total_premium, applied_aptc)
            financial_info.merge!(prorated_amounts: [mid_month_start_hash, mid_month_end_hash])
          end

          return financial_info
        end

        if mid_month_start_date?(financial_dates)
          mid_month_start_hash = mid_month_start_prorated_amount(financial_dates[0], total_premium, applied_aptc)
          financial_info.merge!(prorated_amounts: [mid_month_start_hash])
        end

        if mid_month_end_date?(financial_dates)
          mid_month_end_hash = mid_month_end_prorated_amount(financial_dates[1], total_premium, applied_aptc)
          financial_info.merge!(prorated_amounts: [mid_month_end_hash])
        end

        financial_info
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/MethodLength

      def mid_month_start_prorated_amount(mid_month_start_date, total_premium, applied_aptc)
        start_dates = (mid_month_start_date.end_of_month.day.to_f - mid_month_start_date.day.to_f + 1.0)
        end_dates = mid_month_start_date.end_of_month.day
        multiplying_factor = (start_dates / end_dates)

        {
          partial_month_premium: multiplying_factor * total_premium,
          partial_month_aptc: multiplying_factor * applied_aptc,
          partial_month_start_date: mid_month_start_date,
          partial_month_end_date: mid_month_start_date.end_of_month
        }
      end

      def mid_month_end_prorated_amount(mid_month_end_date, total_premium, applied_aptc)
        multiplying_factor = (mid_month_end_date.day.to_f / mid_month_end_date.end_of_month.day)

        {
          partial_month_premium: multiplying_factor * total_premium,
          partial_month_aptc: multiplying_factor * applied_aptc,
          partial_month_start_date: mid_month_end_date.beginning_of_month,
          partial_month_end_date: mid_month_end_date
        }
      end

      def add_loop_start_date(loop_start_dates, loop_start)
        loop_start_dates << loop_start if within_policy_period?(loop_start)
        loop_start_dates
      end

      def within_policy_period?(loop_start)
        policy_end_date = @policy.policy_end_on
        policy_end_date = @policy.policy_start.end_of_year if policy_end_date.blank?
        (@policy.policy_start..policy_end_date).cover?(loop_start)
      end

      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/CyclomaticComplexity
      def financial_information_loops
        active_enrollees = @policy.enrollees.reject(&:canceled?)
        loop_start_dates = [@policy.policy_start]

        # Incorporate Enrollee Start and End Dates
        active_enrollees.each do |enrollee|
          if enrollee.coverage_start != @policy.policy_start
            loop_start_dates = add_loop_start_date(loop_start_dates, enrollee.coverage_start)
          end

          if enrollee.coverage_end.present? && (enrollee.coverage_end != @policy.policy_end_on)
            loop_start_dates = add_loop_start_date(loop_start_dates, enrollee.coverage_end.next_day)
          end
        end

        # Incorporate APTC Credits Start and End Dates
        # aptc_credits.start_on and aptc_credits.end_on are mandatory fields - presence check not required for end_on date
        @policy.aptc_credits.each do |credit|
          loop_start_dates = add_loop_start_date(loop_start_dates, credit.start_on) if credit.start_on != @policy.policy_start

          if credit.end_on != @policy.policy_end_on
            loop_start_dates = add_loop_start_date(loop_start_dates,
                                                   credit.end_on.next_day)
          end
        end

        loop_start_dates = loop_start_dates.uniq.sort
        loop_start_dates.inject([]) do |loops, start_date|
          next_start_date = loop_start_dates.index(start_date) + 1
          end_date = loop_start_dates[next_start_date].prev_day if loop_start_dates[next_start_date].present?
          loops << [start_date, (end_date || @policy.policy_end_on)]
        end
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/CyclomaticComplexity

      def mid_month_start_date?(financial_dates)
        coverage_period_start = financial_dates[0]
        coverage_period_start.beginning_of_month != coverage_period_start
      end

      def mid_month_end_date?(financial_dates)
        coverage_period_end = financial_dates[1]
        coverage_period_end.present? && (coverage_period_end.end_of_month != coverage_period_end)
      end

      def csr_variant
        if @policy.plan.coverage_type =~ /health/i
          @policy.plan.hios_plan_id.split('-').last
        else
          '01' # Dental always 01
        end
      end

      def postal_code(person)
        address = person.home_address || person.mailing_address
        address.present? ? address.zip : nil
      end

      def format_date(date)
        date = @policy.policy_start.end_of_year if date.blank?
        date.strftime("%Y-%m-%d")
      end
    end
  end
end
