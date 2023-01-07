# frozen_string_literal: true

require "aca_entities/functions/age_on"
module IrsGroups
  # Create and Persist IRS group and its data
  class CalculateDentalPremiumForEnrolledChildren
    include Dry::Monads[:result, :do, :try]
    include EventSource::Command
    require 'dry/monads'
    require 'dry/monads/do'

    def call(params)
      validated_params = yield validate(params)
      dental_premium = yield calculate_premium(validated_params)

      Success(dental_premium)
    end

    private

    def validate(params)
      return Failure("Please pass in enrolled_people") if params[:enrolled_people].blank?
      return Failure("enrollment is blank") if params[:enrollment].blank?
      return Failure("month is blank") if params[:month].blank?

      Success(params)
    end

    def calculate_premium(validated_params)
      @enrollment = validated_params[:enrollment]
      dental_policy = fetch_dental_policy
      return Success(0.0) if dental_policy.blank?

      @child_members = fetch_children_from_dental_enrollment(dental_policy, validated_params[:month])
      return Success(0.0) if @child_members.blank?

      Success(group_ehb_premium(dental_policy.insurance_product))
    end

    def group_ehb_premium(dental_product)
      if dental_product.rating_method == "Age-Based Rates"
        # 'Age-Based Rates'
        total_premium(dental_product)
      else
        # 'Family-Tier Rates'
        family_tier_total_premium(dental_product)
      end
    end

    def family_tier_total_premium(dental_product)
      BigDecimal((family_premium(dental_product) * dental_product.ehb).round(2).to_s)
    end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    def total_premium(dental_product)
      # Finalize total number of members
      members = if @child_members.count > 3
                  @child_members.sort_by do |member|
                    age_function = AcaEntities::Functions::AgeOn.new(on_date: @enrollment.effectuated_on)
                    age_function.call(member.dob)
                  end.last(3)
                else
                  @child_members
                end

      # Finalize members based on Age
      members = members.select do |member|
        age_function = AcaEntities::Functions::AgeOn.new(on_date: @enrollment.effectuated_on)
        age_function.call(member.dob) < 19
      end

      members_premium = members.reduce(0.00) do |sum, member|
        (sum + member.premium_schedule.premium_amount).round(2)
      end

      BigDecimal((members_premium * dental_product.ehb).round(2).to_s)
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength

    def family_premium(dental_product)
      case primary_tier_value
      when 'primary_enrollee'
        dental_product.primary_enrollee
      when 'primary_enrollee_one_dependent'
        dental_product.primary_enrollee_one_dependent
      else
        dental_product.primary_enrollee_many_dependent
      end
    end

    def primary_tier_value
      case @child_members.count
      when 1
        'primary_enrollee'
      when 2
        'primary_enrollee_one_dependent'
      else
        'primary_enrollee_two_dependent'
      end
    end

    def fetch_dental_policy
      insurance_agreement = @enrollment.insurance_policy.insurance_agreement
      insurance_agreement.insurance_policies.detect do |insurance_policy|
        next if insurance_policy.aasm_state == "canceled"

        insurance_policy.insurance_product.coverage_type == "dental" &&
          insurance_policy.insurance_product.plan_year == @enrollment.start_on.year
      end
    end

    def dental_enrollment_for(insurance_policy, month)
      insurance_policy.enrollments_for_month(month, insurance_policy.start_on.year)&.first
    end

    def fetch_children_from_dental_enrollment(insurance_policy, month)
      dental_enrollment = dental_enrollment_for(insurance_policy, month)
      return [] if dental_enrollment.blank?

      enrolled_members = [[dental_enrollment.subscriber] + dental_enrollment.dependents].flatten
      enrolled_members.select do |member|
        age_function = AcaEntities::Functions::AgeOn.new(on_date: @enrollment.effectuated_on)
        age_function.call(member.dob) < 21
      end
    end
  end
end
