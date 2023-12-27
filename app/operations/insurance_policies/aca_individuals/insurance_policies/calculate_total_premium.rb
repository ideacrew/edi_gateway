# frozen_string_literal: true

module InsurancePolicies
  module AcaIndividuals
    module InsurancePolicies
      # This class is responsible for calculating the total premium for a given insurance policy.
      # TODO: - Implement premium calculation for health products. For now this is used only for dental products.
      class CalculateTotalPremium
        include Dry::Monads[:result, :do, :try]
        require 'dry/monads'
        require 'dry/monads/do'

        attr_reader :enrolled_members, :insurance_policy, :calendar_month

        # @param [Hash] params The input parameters for the calculation.
        # @option params [Array] :enrolled_members List of enrolled members.
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
          return Failure("Please pass in enrolled_members") if params[:enrolled_members].blank?
          return Failure("Please pass in is insurance policy") if params[:insurance_policy].blank?
          return Failure("Please pass in is calendar_month") if params[:calendar_month].blank?

          @enrolled_members = params[:enrolled_members]
          @insurance_policy = params[:insurance_policy]
          @calendar_month = params[:calendar_month]
          Success(params)
        end

        # Calculates the total premium based on insurance policy details.
        # @return [Dry::Monads::Result] Returns Success with the calculated total premium or Failure with an error message.
        def calculate_premium
          # TODO: - Implement premium calculation for health products
          return Success(0.0) if insurance_policy.insurance_product.coverage_type == "health"

          result = if insurance_policy.insurance_product.rating_method == "Age-Based Rates"
                     age_based_rating_total_premium
                   else
                     family_based_rating_total_premium(family_premium(insurance_policy.insurance_product),
                                                       enrolled_members.count)
                   end
          Success(result)
        end

        # Calculates the total premium based on age-based rating.
        # @return [Float] The calculated total premium.
        def age_based_rating_total_premium
          return 0.0 if enrolled_members.blank?

          calender_month_begin = Date.new(insurance_policy.start_on.year, calendar_month, 1)
          calender_month_end = calender_month_begin.end_of_month
          end_of_year = insurance_policy.start_on.end_of_year
          calender_month_days = (calender_month_begin..calender_month_end).count
          enrolled_members.sum do |member|
            enrollment = member.aca_individuals_enrollment
            premium_schedule = member.premium_schedule
            member_start_on = [enrollment.start_on, calender_month_begin].max
            member_end_on = [enrollment.end_on || end_of_year, calender_month_end].min
            coverage_days = (member_start_on..member_end_on).count
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
          calender_month_begin = Date.new(insurance_policy.start_on.year, calendar_month, 1)
          calender_month_end = calender_month_begin.end_of_month
          end_of_year = insurance_policy.start_on.end_of_year
          calender_month_days = (calender_month_begin..calender_month_end).count
          enrolled_members.sum do |member|
            enrollment = member.aca_individuals_enrollment
            member_start_on = [enrollment.start_on, calender_month_begin].max
            member_end_on = [enrollment.end_on || end_of_year, calender_month_end].min
            coverage_days = (member_start_on..member_end_on).count
            if calender_month_days == coverage_days
              premium_per_member
            else
              (premium_per_member.to_f / calender_month_days) * coverage_days
            end
          end.round(2)
        end

        # Calculates the family premium based on the dental product.
        # @param [Object] dental_product The dental product object.
        # @return [Float] The calculated family premium.
        def family_premium(dental_product)
          return 0.0 if enrolled_members.blank?

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
          case enrolled_members.count
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
