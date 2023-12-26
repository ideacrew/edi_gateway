# frozen_string_literal: true

require "aca_entities/functions/age_on"
module IrsGroups
  # This class is responsible for calculating the dental premium for enrolled children.
  class CalculateDentalPremiumForEnrolledChildren
    include Dry::Monads[:result, :do, :try]
    include EventSource::Command
    require 'dry/monads'
    require 'dry/monads/do'

    attr_reader :enrollment, :dental_policy

    # Calculates the dental premium for enrolled children based on the provided parameters.
    #
    # @param [Hash] params The input parameters for the calculation.
    # @option params [Array] :enrolled_people List of enrolled people.
    # @option params [Object] :enrollment The enrollment object.
    # @option params [Integer] :month The month for which the premium is calculated.
    # @return [Dry::Monads::Result] Returns Success with the calculated dental premium or Failure with an error message.
    def call(params)
      validated_params = yield validate(params)
      @dental_policy = yield fetch_dental_policy
      dental_premium = yield calculate_premium(validated_params)

      Success(dental_premium)
    end

    private

    # Validates the input parameters.
    #
    # @param [Hash] params The input parameters.
    # @return [Dry::Monads::Result] Returns Success with the validated params or Failure with an error message.
    def validate(params)
      return Failure("Please pass in enrolled_people") if params[:enrolled_people].blank?
      return Failure("enrollment is blank") if params[:enrollment].blank?
      return Failure("month is blank") if params[:month].blank?

      @enrollment = params[:enrollment]
      Success(params)
    end

    # Fetches the dental policy associated with the enrollment.
    #
    # @return [Dry::Monads::Result] Returns Success with the fetched dental policy or Failure with an error message.
    def fetch_dental_policy
      insurance_policies = @enrollment.insurance_policy.irs_group.aca_individual_insurance_policies
      policy = insurance_policies.detect do |insurance_policy|
        next if insurance_policy.aasm_state == "canceled"

        insurance_policy.insurance_product.coverage_type == "dental" &&
          (insurance_policy.start_on..insurance_policy.policy_end_on).cover?(@enrollment.start_on) &&
          insurance_policy.insurance_product.plan_year == @enrollment.start_on.year
      end
      Success(policy)
    end

    # Calculates the dental premium based on the provided parameters.
    #
    # @param [Hash] validated_params The validated input parameters.
    # @return [Dry::Monads::Result] Returns Success with the calculated dental premium or Failure with an error message.
    def calculate_premium(validated_params)
      return Success(0.0) if dental_policy.blank?
      return Success(0.0) if no_eligible_enrolled_members_on_dental_policy(validated_params[:enrolled_people],
                                                                           validated_params[:month])

      @child_members = fetch_children_from_dental_enrollment(validated_params[:enrolled_people],
                                                             validated_params[:month])
      return Success(0.0) if @child_members.blank?

      eligible_members = fetch_valid_child_members(dental_policy.insurance_product, @child_members)
      params = { enrolled_members: eligible_members, insurance_policy: dental_policy,
                 calendar_month: validated_params[:month] }
      result = ::InsurancePolicies::AcaIndividuals::InsurancePolicies::CalculateTotalPremium.new.call(params)
      return Success(0.0) if result.failure?

      Success(BigDecimal((result.value! * dental_policy.insurance_product.ehb).round(2).to_s))
    end

    # Checks if there are no eligible enrolled members on the dental policy for a given month.
    #
    # @param [Array] enrolled_people List of enrolled people.
    # @param [Integer] month The month for which the check is performed.
    # @return [Boolean] Returns true if there are no eligible enrolled members, false otherwise.
    def no_eligible_enrolled_members_on_dental_policy(enrolled_people, month)
      dental_enrollment = dental_enrollment_for(month)
      return true if dental_enrollment.blank?

      enrolled_people_hbx_ids = enrolled_people.flat_map(&:person).flat_map(&:hbx_id).uniq
      [[dental_enrollment.subscriber] + dental_enrollment.dependents].flatten.none? do |enrollee|
        enrolled_people_hbx_ids.include?(enrollee.person.hbx_id)
      end
    end

    # Fetches children from dental enrollment based on the provided parameters.
    #
    # @param [Array] enrolled_people List of enrolled people.
    # @param [Integer] month The month for which children are fetched.
    # @return [Array] Returns an array of child members.
    def fetch_children_from_dental_enrollment(enrolled_people, month)
      dental_enrollment = dental_enrollment_for(month)
      enrolled_people_hbx_ids = enrolled_people.flat_map(&:person).flat_map(&:hbx_id).uniq
      return [] if dental_enrollment.blank?

      enrolled_members = [[dental_enrollment.subscriber] + dental_enrollment.dependents].flatten
      enrolled_members.select do |member|
        age_function = AcaEntities::Functions::AgeOn.new(on_date: @enrollment.effectuated_on)
        age_function.call(member.dob) < 21 && enrolled_people_hbx_ids.include?(member.person.hbx_id)
      end
    end

    # Fetches the dental enrollment for a given month.
    #
    # @param [Integer] month The month for which dental enrollment is fetched.
    # @return [Object] Returns the dental enrollment object.
    def dental_enrollment_for(month)
      dental_policy.enrollments_for_month(month, dental_policy.start_on.year)&.first
    end

    # Fetches valid child members based on the dental product and provided members.
    #
    # @param [Object] dental_product The dental product object.
    # @param [Array] members List of members.
    # @return [Array] Returns an array of valid child members.
    def fetch_valid_child_members(dental_product, members)
      if dental_product.rating_method == "Age-Based Rates"
        age_rated_valid_members(members)
      else
        family_tier_valid_members(members)
      end
    end

    # Filters valid members for age-based rating.
    #
    # @param [Array] members List of members.
    # @return [Array] Returns an array of valid members for age-based rating.
    def age_rated_valid_members(members)
      valid_members = if members.count > 3
                        members.sort_by do |member|
                          age_function = AcaEntities::Functions::AgeOn.new(on_date: @enrollment.effectuated_on)
                          age_function.call(member.dob)
                        end.last(3)
                      else
                        members
                      end

      valid_members.select do |member|
        age_function = AcaEntities::Functions::AgeOn.new(on_date: @enrollment.effectuated_on)
        age_function.call(member.dob) < 19
      end
    end

    # Filters valid members for family-tier rating.
    #
    # @param [Array] members List of members.
    # @return [Array] Returns an array of valid members for family-tier rating.
    def family_tier_valid_members(members)
      members.select do |member|
        age_function = AcaEntities::Functions::AgeOn.new(on_date: @enrollment.effectuated_on)
        age_function.call(member.dob) < 19
      end
    end
  end
end
