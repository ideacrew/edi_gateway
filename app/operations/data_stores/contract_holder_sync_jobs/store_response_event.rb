# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module DataStores
  module ContractHolderSyncJobs
    # Operation to update ContractHolderSubject with response event and cv3 payload
    class StoreResponseEvent
      send(:include, Dry::Monads[:result, :do])

      # @param [Hash] params the parameters used update ContractHolderSubject with response event and cv3 payload
      def call(params)
        values   = yield validate(params)
        sync_job = yield find_contract_holder_sync_job(values)
        subject  = yield find_contract_holder_subject(values, sync_job)
        subject  = yield store_response_event(values, subject)

        Success(subject)
      end

      private

      def validate(params)
        errors = []
        errors << "sync_job_id is required" unless params[:sync_job_id]
        errors << "primary_person_hbx_id is required" unless params[:primary_person_hbx_id]
        errors << "family is required" unless params[:family]
        errors << "event_name is required" unless params[:event_name]

        errors.present? ? Failure(errors) : Success(params)
      end

      def find_contract_holder_sync_job(values)
        sync_job = DataStores::ContractHolderSyncJob.where(:id => values[:sync_job_id]).first

        if sync_job
          Success(sync_job)
        else

          Failure("unable to find sync job with #{values}")
        end
      end

      def find_contract_holder_subject(values, sync_job)
        subject = sync_job.subjects.where(primary_person_hbx_id: values[:primary_person_hbx_id]).first

        if subject
          Success(subject)
        else

          Failure("unable to find subject with #{values}")
        end
      end

      def store_response_event(values, subject)
        response_event = Integrations::Events::Build.new.call({
                                                                name: values[:event_name],
                                                                body: values[:family]
                                                              }).success

        subject.update(response_event: response_event)
        Success(subject)
      end
    end
  end
end
