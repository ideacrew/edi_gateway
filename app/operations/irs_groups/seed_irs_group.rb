# frozen_string_literal: true

module IrsGroups
  # Parse CV3 family payload and store necessary information
  class SeedIrsGroup
    include Dry::Monads[:result, :do, :try]
    include EventSource::Command
    require 'dry/monads'
    require 'dry/monads/do'

    def call(params)
      input_hash = yield parse_json(params)
      validated_family_hash = yield validate_family_json_hash(input_hash)
      family = yield build_family_entity(validated_family_hash)
      policies = yield FetchPoliciesFromGlue.new.call(family)
      result = yield CreateAndPersistIrsGroup.new.call({ family: family, policies: policies })
      Success(result)
    end

    private

    def parse_json(json_string)
      parsing_result = Try do
        JSON.parse(json_string, :symbolize_names => true)
      end
      parsing_result.or do
        Failure(:invalid_json)
      end
    end

    def validate_family_json_hash(input_hash)
      validation_result = AcaEntities::Contracts::Families::FamilyContract.new.call(input_hash)
      validation_result.success? ? Success(validation_result.values) : Failure(validation_result.errors)
    end

    def build_family_entity(family_hash)
      result = Try do
        AcaEntities::Families::Family.new(family_hash)
      end

      result.or do |e|
        Failure(e)
      end
    end
  end
end
