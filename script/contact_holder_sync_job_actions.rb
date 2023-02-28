# frozen_string_literal: true

# request family payloads for the subjects under given sync job
class ContractHolderSyncJobActions
  include EventSource::Command

  attr_reader :sync_job

  def initialize(sync_job)
    @sync_job = sync_job
  end

  def request_family_payloads
    @error_handler = ::Integrations::Error.new

    sync_job.subjects.each do |subject|
      @error_handler.capture_exception_with(subject.primary_person_hbx_id) do
        event = build_event(subject)
        raise event.failure unless event.success?

        event = event.success
        event_headers = event.headers.dup
        event.publish
        persist_request_event(subject, event, event_headers)
      end
    end

    close_sync_job
  end

  def build_event(subject)
    event_name = 'events.families.find_by_requested'
    correlation_id = subject.contract_holder_sync.job_id
    event_payload = { person_hbx_id: subject.primary_person_hbx_id }

    event(event_name, attributes: event_payload, headers: { correlation_id: correlation_id })
  end

  def persist_request_event(subject, event, event_headers)
    request_event =
      ::Integrations::Events::Build
      .new
      .call({ name: event.name, body: event.payload, headers: event_headers.to_json })
      .success
    subject.update(request_event: request_event, status: :transmitted)
  end

  def close_sync_job
    status = :transmitted
    status = :errored if @error_handler.errors_found?
    sync_job.update(status: status, error_messages: @error_handler.error_messages)
    sync_job
  end
end
