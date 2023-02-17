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
        _response_event = yield update_edidb(subject)
        response = yield send_family_payload(subject)

        Success(response)
      end

      private

      def validate(params)
        errors = []
        errors << 'correlation_id is required' unless params[:correlation_id]
        errors << 'primary_person_hbx_id is required' unless params[:primary_person_hbx_id]
        errors << 'family is required' unless params[:family]
        errors << 'event_name is required' unless params[:event_name]

        errors.present? ? Failure(errors) : Success(params)
      end

      def find_contract_holder_sync_job(values)
        sync_job = DataStores::ContractHolderSyncJob.where(job_id: values[:correlation_id]).first

        sync_job ? Success(sync_job) : Failure("unable to find sync job with #{values}")
      end

      def find_contract_holder_subject(values, sync_job)
        subject = sync_job.subjects.where(primary_person_hbx_id: values[:primary_person_hbx_id]).first

        subject ? Success(subject) : Failure("unable to find subject with #{values}")
      end

      def store_response_event(values, subject)
        response_event =
          Integrations::Events::Build.new.call({ name: values[:event_name], body: values[:family].to_json })
        return Failure("unable to create response event #{response_event.failure}") if response_event.failure?

        subject.update(response_event: response_event.success)
        Success(subject)
      end

      def update_edidb(subject)
        result = contract_holder_update_service.call(subject: subject)

        if result.success?
          subject.response_event.update(status: :transmitted)
          Success(subject.response_event)
        else
          subject.response_event.update(status: :errored, error_messages: error_messages(result))
          Failure(subject.response_event)
        end
      end

      def send_family_payload(subject)
        event =
          event(
            'events.insurance_policies.tax1095a_payload.requested',
            attributes: {
              primary_person_hbx_id: subject.primary_person_hbx_id,
              sync_job_id: subject.contract_holder_sync.job_id
            }
          ).success

        event.publish
        Success("Successfully published the payload for event: #{subject.primary_person_hbx_id}")
      end

      def error_messages(result)
        result.failure.is_a?(Dry::Validation::Result) ? [result.failure.errors.to_h] : [result.failure]
      end

      def contract_holder_update_service
        ::InsurancePolicies::ContractHolders::CreateOrUpdate.new
      end
    end
  end
end
