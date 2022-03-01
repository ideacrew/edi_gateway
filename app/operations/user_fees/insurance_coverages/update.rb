# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module UserFees
  module InsuranceCoverages
    # Update an existing {UserFees::InsuranceCoverage} record in the database
    class Update
      include Dry::Monads[:result, :do, :try]

      # @param [Hash] opts an {EnrollmentUpdated} event
      # @option opts [Hash] :customer required
      # @return [Dry::Monad::Success] customer record created
      # @return [Dry::Monad::Failure] failed to create customer record
      def call(params)
        values = yield validate(params)
        customer = yield create(values)

        Success(customer)
      end

      private

      def validate(params); end

      def create(values); end
    end
  end
end
