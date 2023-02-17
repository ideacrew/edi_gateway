# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module DataStores
  module ContractHolderSyncJobs
    # Operation to create ContractHolderSyncJob
    class Create
      send(:include, Dry::Monads[:result, :do])

      # @param [Hash] params the parameters used to create a new job
      # @return [Dry::Monad::Success] Sync job created
      # @return [Dry::Monad::Failure] failed to create Sync job
      def call(params)
        values = yield validate(params)
        # sync_job = yield find_contract_holder_sync_job(values)
        sync_job = yield create(values)

        Success(sync_job)
      end

      private

      def validate(params)
        errors = []
        errors << "start_time is required" unless params[:start_time]
        errors << "end_time is required" unless params[:end_time]
        errors << "status is required" unless params[:status]

        errors.present? ? Failure(errors) : Success(params)
      end

      def create(values)
        sync_job = DataStores::ContractHolderSyncJob.create(
          time_span_start: values[:start_time],
          time_span_end: values[:end_time],
          status: values[:status]
        )

        Success(sync_job)
      end
    end
  end
end
