# frozen_string_literal: true

module InsurancePolicies
  module AcaIndividuals
    module InsurancePolicies
      # This class is responsible for calculating the total premium for a given insurance policy.
      # TODO: - Implement premium calculation for health products. For now this is used only for dental products.
      class CalculatePediatricDentalPremium
        include Dry::Monads[:result, :do, :try]
        require 'dry/monads'
        require 'dry/monads/do'

        attr_reader :dental_enrolled_members, :dental_policy, :calendar_month, :health_enrolled_members

        # @param [Hash] params The input parameters for the calculation.
        # @option params [Array] :health_eligible_members List of health eligible members.
        #  # @option params [Array] :dental_eligible_members List of dental eligible members.
        # @option params [Object] :insurance_policy The insurance policy object.
        # @option params [Integer] :calendar_month The calendar month for which the premium is calculated.
        # @return [Dry::Monads::Result] Returns Success with the calculated total premium or Failure with an error message.
        def call(params)
          _validated_params = yield validate(params)
          total_premium = yield calculate_premium

          Success(total_premium)
        end

        private

        # Validates the input parameters.
        # @param [Hash] params The input parameters.
        # @return [Dry::Monads::Result] Returns Success with the validated params or Failure with an error message.
        def validate(params)
          return Failure("Please pass in dental_eligible_members") if params[:dental_eligible_members].blank?
          return Failure("Please pass in health_eligible_members") if params[:health_eligible_members].blank?
          return Failure("Please pass in is dental policy") if params[:dental_policy].blank?
          return Failure("Please pass in is calendar_month") if params[:calendar_month].blank?

          @dental_enrolled_members = params[:dental_eligible_members]
          @health_enrolled_members = params[:health_eligible_members]
          @dental_policy = params[:dental_policy]
          @calendar_month = params[:calendar_month]
          Success(params)
        end

        # Calculates the total premium based on insurance policy details.
        # @return [Dry::Monads::Result] Returns Success with the calculated total premium or Failure with an error message.
        def calculate_premium
          result = if dental_policy.insurance_product.rating_method == "Age-Based Rates"
                     age_based_rating_total_premium
                   else
                     family_based_rating_total_premium(family_premium(dental_policy.insurance_product),
                                                       dental_enrolled_members.count)
                   end
          Success(result)
        end

        # Calculates the total premium based on age-based rating.
        # @return [Float] The calculated total premium.
        def age_based_rating_total_premium
          return 0.0 if dental_enrolled_members.blank?

          calender_month_begin = Date.new(dental_policy.start_on.year, calendar_month, 1)
          calender_month_end = calender_month_begin.end_of_month
          calender_month_days = (calender_month_begin..calender_month_end).count
          dental_enrolled_members.sum do |dental_enrolled_member|
            valid_health_members = fetch_valid_health_members(dental_enrolled_member)
            dental_enrollment = dental_enrolled_member.aca_individuals_enrollment
            premium_schedule = dental_enrolled_member.premium_schedule
            health_covered_days = health_covered_days(valid_health_members)
            dental_covered_days = dental_covered_days(dental_enrollment)
            coverage_days = [health_covered_days, dental_covered_days].min
            premium_rate = premium_schedule.premium_amount

            if calender_month_days == coverage_days
              premium_rate
            else
              (premium_rate.to_f / calender_month_days) * coverage_days
            end
          end.round(2).to_f
        end

        # Calculates the total premium based on family-based rating.
        # @param [Float] family_premium The family premium.
        # @param [Integer] members_count The count of enrolled members.
        # @return [Float] The calculated total premium.
        def family_based_rating_total_premium(family_premium, members_count)
          return 0.0 if family_premium.blank? || members_count.blank?

          premium_per_member = (family_premium / members_count).round(2)
          calender_month_begin = Date.new(dental_policy.start_on.year, calendar_month, 1)
          calender_month_end = calender_month_begin.end_of_month
          calender_month_days = (calender_month_begin..calender_month_end).count
          dental_enrolled_members.sum do |dental_enrolled_member|
            valid_health_members = fetch_valid_health_members(dental_enrolled_member)
            dental_enrollment = dental_enrolled_member.aca_individuals_enrollment
            health_covered_days = health_covered_days(valid_health_members)
            dental_covered_days = dental_covered_days(dental_enrollment)
            coverage_days = [health_covered_days, dental_covered_days].min
            if calender_month_days == coverage_days
              premium_per_member
            else
              (premium_per_member.to_f / calender_month_days) * coverage_days
            end
          end.round(2)
        end

        # Fetches valid health members associated with a given dental enrolled member.
        #
        # @param dental_enrolled_member [Object] The dental enrolled member object.
        # @return [Array<Object>] An array of valid health members associated with the given dental enrolled member.
        def fetch_valid_health_members(dental_enrolled_member)
          health_enrolled_members.select do |hm|
            hm.person.hbx_id == dental_enrolled_member.person.hbx_id
          end
        end

        # Calculates the total covered days for health members within a specified month.
        #
        # @param health_members [Array<Object>] An array of health members.
        # @return [Integer] The total covered days for health members in the specified month.
        def health_covered_days(health_members)
          health_enrollments = health_members.flat_map(&:aca_individuals_enrollment).compact
          health_enrollment_start_on = health_enrollments.map(&:start_on).min
          health_enrollment_end_on = health_enrollments.map do |health_enrollment|
            health_enrollment.end_on || health_enrollment.start_on.end_of_month
          end.max
          calculate_coverage_days(health_enrollment_start_on, health_enrollment_end_on,
                                  dental_policy.start_on.year, calendar_month)
        end

        # Calculates the total covered days for a dental enrollment within a specified month.
        #
        # @param dental_enrollment [Object] The dental enrollment object.
        # @return [Integer] The total covered days for the dental enrollment in the specified month.
        def dental_covered_days(dental_enrollment)
          dental_enrollment_start_on = dental_enrollment.start_on
          dental_enrollment_end_on = dental_enrollment.end_on || dental_enrollment_start_on.end_of_month
          calculate_coverage_days(dental_enrollment_start_on, dental_enrollment_end_on,
                                  dental_policy.start_on.year, calendar_month)
        end

        # Calculates the coverage days between two dates within a specified month.
        #
        # @param start_date [Date] The start date of the coverage period.
        # @param end_date [Date] The end date of the coverage period.
        # @param year [Integer] The year of the specified month.
        # @param month [Integer] The month for which coverage is calculated.
        # @return [Integer] The total coverage days between the specified start and end dates in the given month.
        def calculate_coverage_days(start_date, end_date, year, month)
          start_month_day =
            if start_date.year == year && start_date.month == month
              start_date.day
            else
              1
            end

          end_month_day =
            if end_date.year == year && end_date.month == month
              end_date.day
            else
              Date.new(year, month, -1).day
            end

          [end_month_day, start_month_day].max - [start_month_day, end_month_day].min + 1
        end

        # Calculates the family premium based on the dental product.
        # @param [Object] dental_product The dental product object.
        # @return [Float] The calculated family premium.
        def family_premium(dental_product)
          return 0.0 if dental_enrolled_members.blank?

          case primary_tier_value
          when 'primary_enrollee'
            dental_product.primary_enrollee
          when 'primary_enrollee_one_dependent'
            dental_product.primary_enrollee_one_dependent
          else
            dental_product.primary_enrollee_two_dependent
          end
        end

        # Determines the primary tier value based on the count of enrolled members.
        # @return [String] The primary tier value.
        def primary_tier_value
          case dental_enrolled_members.count
          when 1
            'primary_enrollee'
          when 2
            'primary_enrollee_one_dependent'
          else
            'primary_enrollee_two_dependent'
          end
        end
      end
    end
  end
end
