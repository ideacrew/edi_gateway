# frozen_string_literal: true

module IrsGroups
  # Fetch subscriber from CV3 Family payload and fetch policies from glue using the subscriber
  class FetchPoliciesFromGlue
    include Dry::Monads[:result, :do, :try]
    include EventSource::Command

    # @param params [Hash] The params to parse and construct h36 payload
    def call(params)
      family = yield validate_family(params[:family])
      @primary_person = yield fetch_primary_person(family)
      policies = yield fetch_active_health_policies_from_glue

      Success(policies)
    end

    # Validate input object
    def validate_family(family)
      if family.is_a?(::AcaEntities::Families::Family)
        Success(family)
      else
        Failure("Invalid Family, given value is not a ::AcaEntities::Families::Family class")
      end
    end

    def fetch_primary_person(family)
      primary_family_member =
        family.family_members.detect(&:is_primary_applicant)
      if primary_family_member
        Success(primary_family_member.person)
      else
        Failure('No Primary Applicant in family members')
      end
    end

    # fetching person and policies from Glue by using glue db as a readonly database
    def fetch_active_health_policies_from_glue
      glue_person = Person.find_for_member_id(@primary_person.hbx_id)

      return Failure("Unable to find person in glue") if glue_person.blank?

      # TODO: look for policies where this person is present as a responsible party or as a subscriber
      active_policies = glue_person.policies.select do |policy|
        policy.coverage_type == "health" && %w[submitted terminated].include?(policy.aasm_state)
      end

      return Failure("No active policies") if active_policies.blank?

      Success(active_policies)
    end
  end
end
