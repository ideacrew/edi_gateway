# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module InsurancePolicies
  # Persist contract holder sync job with subjects into the database
  class Refresh
    send(:include, Dry::Monads[:result, :do])
    include EventSource::Command

    attr_reader :error_handler

    def call(params)
      values = yield validate(params)
      sync_job = yield create_sync_job(values)
      query = yield create_new_query(values)
      sync_job = yield persist_subscriber_policies(sync_job, query)
      sync_job = yield persist_responsible_party_policies(sync_job, query)
      sync_job = yield request_family_payloads(sync_job)
      sync_job = yield close_sync_job(sync_job)

      Success(sync_job)
    end

    private

    def validate(params)
      return Failure('start_time is required') unless params[:start_time].present?
      return Failure('end_time is required') unless params[:end_time].present?

      @error_handler = Integrations::Error.new

      Success(params)
    end

    def create_sync_job(values)
      job_params = values.slice(:start_time, :end_time)
      job_params[:status] = :processing

      DataStores::ContractHolderSyncJobs::Create.new.call(job_params)
    end

    def create_new_query(values)
      query = GluePolicyQuery.new(values[:start_time], values[:end_time])

      Success(query)
    end

    def persist_subscriber_policies(sync_job, policy_query)
      policy_query.policies_by_subscriber do |result|
        @error_handler.capture_exception_with(result['_id']) do
          subject_create_or_update(
            {
              contract_holder_sync_job: sync_job,
              primary_person_hbx_id: result['_id'],
              subscriber_policies: result['enrolled_policies']
            }
          )
        end
      end

      Success(sync_job)
    end

    # rubocop:disable Metrics/MethodLength
    def persist_responsible_party_policies(sync_job, policy_query)
      policy_query.policies_by_responsible_party do |result|
        @error_handler.capture_exception do
          responsible_person = responsible_party_person_for(result['_id'])
          next if @error_handler.errored_on?(responsible_person.authority_member_id)
          raise "unable to find person record for with responsible party #{result['_id']}" unless responsible_person

          @error_handler.capture_exception_with(responsible_person.authority_member_id) do
            subject_create_or_update(
              {
                contract_holder_sync_job: sync_job,
                primary_person_hbx_id: responsible_person.authority_member_id,
                responsible_party_policies: result['enrolled_policies']
              }
            )
          end
        end
      end

      Success(sync_job)
    end

    # rubocop:enable Metrics/MethodLength

    def subject_create_or_update(options)
      response = DataStores::ContractHolderSubjects::CreateOrUpdate.new.call(options)
      raise response.failure if response.failure?
    end

    def request_family_payloads(sync_job)
      sync_job.subjects.each do |subject|
        @error_handler.capture_exception_with(subject.primary_person_hbx_id) do
          event = build_event(subject)
          raise event.failure unless event.success?

          event.success.publish
          persist_request_event(subject, event.success)
        end
      end

      Success(sync_job)
    end

    def build_event(subject)
      event_name = 'events.families.find_by_requested'
      correlation_id = subject.contract_holder_sync.job_id
      event_payload = { primary_person_hbx_id: subject.primary_person_hbx_id }

      event(event_name, attributes: event_payload, headers: { correlation_id: correlation_id })
    end

    def persist_request_event(subject, event, errors = [])
      request_event =
        Integrations::Events::Build.new.call({ name: event.name, body: event.payload, errors: errors }).success
      subject.update(request_event: request_event, status: :transmitted)
    end

    def close_sync_job(sync_job)
      status = :transmitted
      status = :errored if @error_handler.errors_found?
      sync_job.update(status: status, error_messages: @error_handler.error_messages)

      Success(sync_job)
    end

    def responsible_party_person_for(responsible_party_id)
      Person.where('responsible_parties._id': responsible_party_id).first
    end
  end
end
