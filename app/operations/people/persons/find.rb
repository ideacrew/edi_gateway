# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module People
  module Persons
    # Operation to find person by hbx id.
    class Find
      send(:include, Dry::Monads[:result, :do])

      def call(params)
        validated_params = yield validate(params)
        insurance_product = yield find_person(validated_params)

        Success(insurance_product)
      end

      private

      def validate(params)
        return Failure('Person hbx_id cannot be blank') if params[:hbx_id].blank?

        Success(params)
      end

      def find_person(validated_params)
        person = People::Person.where(hbx_id: validated_params[:hbx_id]).first
        if person.present?
          person_hash = person.as_json(include: %i[addresses emails phones name]).deep_symbolize_keys
          Success(person_hash)
        else
          Failure("Unable to find person with ID #{validated_params[:hbx_id]}.")
        end
      rescue StandardError
        Failure("Unable to find person with #{validated_params[:hbx_id]}.")
      end
    end
  end
end
