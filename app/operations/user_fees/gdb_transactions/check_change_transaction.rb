# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module UserFees
  module GdbTransactions
    # Resolve whether passed transaction message is an enrollment change
    #
    class CheckChangeTransaction
      include Dry::Monads[:result, :do, :try]

      # @param [Hash] params the parameters to resolve message type
      # @option params [Hash] :message EDI Database transaction (required)
      # @return [Dry::Monad::Success] message is a change
      # @return [Dry::Monad::Failure] message is not a change
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
        # change_insurance_coverage
        # change tax_household
        ## aptc or csr change
        ## members (is this really a term/add?)
        # change_policy
        ## change policy effective date
        ## premium change for rating area change
        ## premium change for tobacco rating change
        # change_enrolled_member
        ## change effective date
        ## change identifying_info
        ## other?
      end
    end
  end
end
