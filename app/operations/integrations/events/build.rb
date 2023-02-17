# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Integrations
  module Events
    # Operation to build Integrations Event
    class Build
      send(:include, Dry::Monads[:result, :do])

      # @param [Hash] params the parameters to build new event
      # @return [Dry::Monad::Success] event instance
      # @return [Dry::Monad::Failure] failed with validation errors
      def call(params)
        values = yield validate(params)
        event = yield build(values)

        Success(event)
      end

      private

      def validate(params)
        errors = []
        errors << "name is required" unless params[:name]
        errors << "body is required" unless params[:body]
        params[:errors] ||= []
        errors << "errors array expected" unless params[:errors].is_a?(Array)

        errors.blank? ? Success(params) : Failure(errors)
      end

      def build(values)
        attributes = values.slice(:name, :body)
        attributes[:error_messages] = values[:errors]
        attributes[:status] = values[:errors].present? ? :errored : :transmitted

        Success(Integrations::Event.new(attributes))
      end
    end
  end
end
