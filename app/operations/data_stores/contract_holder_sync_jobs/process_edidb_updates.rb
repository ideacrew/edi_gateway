# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module DataStores
  module ContractHolderSubjects
    # Operation to create or update ContractHolderSubjects
    class ProcessEdidbUpdates
      send(:include, Dry::Monads[:result, :do])
      include EventSource::Command

      def call(params)
        values          = yield validate(params)
        ch_sync_job     = yield find_contract_holder_sync_job(values)
        output          = yield process(ch_sync_job)

        Success(output)
      end

      private

      def validate(params)
        return Failure('sync_job id expected') unless params[:sync_job_id]

        Success(values)
      end

      def find_contract_holder_sync_job(values)
        sync_job = DataStores::ContractHolderSyncJob.find(values[:sync_job_id])

        Success(sync_job)
      end

      def process(ch_sync_job)
        ch_sync_job.subjects.each do |subject|
          request_db_update_for(ch_sync_job, subject)
        end

        Success(true)
      end

      def request_db_update_for(ch_sync_job, subject)
        event_payload = { sync_job_id: ch_sync_job.id, primary_person_hbx_id: subject.primary_person_hbx_id }.to_json
        event = event("events.data_stores.contract_holder_subjects.edidb_update_requested", attributes: event_payload)
        event.success.publish
      end
    end
  end
end
