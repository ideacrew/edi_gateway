# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module UserFees
  module InsuranceCoverages
    # Persist a new {UserFees::Customer record in the database
    class Create
      send(:include, Dry::Monads[:result, :do])

      # @param [Hash] opts the parameters used to create a new Customer
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
