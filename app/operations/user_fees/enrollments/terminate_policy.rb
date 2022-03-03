# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module UserFees
  module Enrollments
    # Resolve whether passed transaction message is an enrollment addition
    #
    class TerminatePolicy
      include Dry::Monads[:result, :do, :try]

      # @param [Hash] params the parameters to resolve message type
      # @option params [Hash] :message EDI Database transaction (required)
      # @return [Dry::Monad::Success] message is a addition
      # @return [Dry::Monad::Failure] message is not a addition
      def call(params)
        message = yield validate(params)
        result = yield classify_transaction(message)

        Success(result)
      end

      private

      def validate(message)
        return Success(message) if message.is_an_instance_of Hash
        Failure('hash expected')
      end

      def classify_transaction(message)
        # add_insurance_coverage
        # add_tax_household
        # add_policy
        # add_enrolled_member
      end
    end
  end
end
