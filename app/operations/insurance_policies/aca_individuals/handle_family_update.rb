# frozen_string_literal: true


module InsurancePolicies
  module AcaIndividuals
    class HandleFamilyUpdate
      include Dry::Monads[:result, :do, :try]
      include EventSource::Command
      require 'dry/monads'
      require 'dry/monads/do'

      def call(params)
        json_hash = yield parse_json(params)
        validated_family_hash = yield validate_family_json_hash(json_hash)
        family = yield build_family(validated_family_hash)
        policies = yield FetchPoliciesFromGlue.new.call(family)
        PersistH36Data.new.call({family: family, policies: policies})
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

      def validate_family_json_hash(json_hash)
        validation_result = AcaEntities::Contracts::Families::FamilyContract.new.call(json_hash)

        Success(validation_result.values)
      end

      def build_family(family_hash)
        result = Try do
          AcaEntities::Families::Family.new(family_hash)
        end

        result.or do |e|
          Failure(e)
        end
      end
    end
  end
end
