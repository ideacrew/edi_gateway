# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module DataStores
  module ContractHolderSyncJobs
    # Operation to update ContractHolderSubject with response event and cv3 payload
    class ProcessResponseEvent
      send(:include, Dry::Monads[:result, :do])

      # @param [Hash] params the parameters used update ContractHolderSubject with response event and cv3 payload
      def call(params)
        values = yield validate(params)
        sync_job = yield find_contract_holder_sync_job(values)
        subject = yield find_contract_holder_subject(values, sync_job)
        subject = yield store_response_event(values, subject)
        output = yield process_response_event(subject)

        Success(output)
      end

      private

      def validate(params)
        errors = []
        errors << 'sync_job_id is required' unless params[:sync_job_id]
        errors << 'primary_person_hbx_id is required' unless params[:primary_person_hbx_id]
        errors << 'family is required' unless params[:family]
        errors << 'event_name is required' unless params[:event_name]

        errors.present? ? Failure(errors) : Success(params)
      end

      def find_contract_holder_sync_job(values)
        sync_job = DataStores::ContractHolderSyncJob.where(id: values[:sync_job_id]).first

        sync_job ? Success(sync_job) : Failure("unable to find sync job with #{values}")
      end

      def find_contract_holder_subject(values, sync_job)
        subject = sync_job.subjects.where(primary_person_hbx_id: values[:primary_person_hbx_id]).first

        subject ? Success(subject) : Failure("unable to find subject with #{values}")
      end

      def store_response_event(values, subject)
        response_event = Integrations::Events::Build.new.call({ name: values[:event_name], body: values[:family] })
        return Failure("unable to create response event #{response_event.failure}") if response_event.failure?

        subject.update(response_event: response_event.success)
        Success(subject)
      end

      # add spec to test peristance on the response event
      def update_edidb(subject)
        result = InsuracePolicies::ContractHolders::CreateOrUpdate.new.call(subject: subject)

        response_event = subject.response_event
        if result.success?
          response_event.update(status: :transmitted)
        else
          response_event.update(errors: result.failure.errors, status: :errored)
        end

        result
      end
    end
  end
end
