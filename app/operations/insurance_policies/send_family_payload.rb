# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module InsurancePolicies
  # Persist contract holder sync job with subjects into the database
  class SendFamilyPayload
    send(:include, Dry::Monads[:result, :do])
    include EventSource::Command

    def call(params)
      values = yield validate(params)
      subject = yield find_contract_holder_subject(values)
      subject = yield validate_subject(subject)
      policies_by_year = yield find_affected_policies_by_year(subject)
      cv3_payloads = yield send_family_payloads(subject, policies_by_year)
      subject = yield publish_family_cv_payloads(subject, policies_by_year, cv3_payloads)

      Success(subject)
    end

    private

    def validate(params)
      return Failure('sync_job_id is required') unless params[:sync_job_id]
      return Failure('primary_person_hbx_id is required') unless params[:primary_person_hbx_id]

      @error_handler = ::Integrations::Error.new

      Success(params)
    end

    def find_contract_holder_subject(values)
      sync_job = ::DataStores::ContractHolderSyncJob.where(job_id: values[:sync_job_id]).first
      subject = sync_job.subjects.where(primary_person_hbx_id: values[:primary_person_hbx_id]).first

      Success(subject)
    end

    def validate_subject(subject)
      response_event = subject.response_event
      return Failure('unable to find response event') unless response_event
      return Failure('subject response event has errors') unless response_event.transmitted?

      Success(subject)
    end

    def find_affected_policies_by_year(subject)
      policies = Policy.where(:eg_id.in => (subject.subscriber_policies + subject.responsible_party_policies))
      policies_by_year = policies.group_by { |p| p.policy_start.year }
      Success(policies_by_year)
    end

    def send_family_payloads(subject, policies_by_year)
      cv3_payloads = {}
      policies_by_year.each do |calendar_year, policies|
        @error_handler.capture_exception do
          payload = build_cv_payload_with(subject, calendar_year, policies)
          raise "cv3 family payload errored for #{policies.map(&:eg_id)}" unless payload.success?

          cv3_payloads[calendar_year] = payload.success
        end
      end

      if @error_handler.error_messages.any?
        store_transmit_events_with_errors(subject, policies_by_subscriber)
        Failure(@error_handler.error_messages)
      else
        Success(cv3_payloads)
      end
    end

    def build_cv_payload_with(subject, calendar_year, _policies)
      ::Tax1095a::Transformers::InsurancePolicies::Cv3Family.new.call(
        {
          tax_year: calendar_year,
          tax_form_type: payload[:tax_form_type],
          irs_group_id: payload[:irs_group_id],
          affected_policies: subject.subscriber_policies + subject.responsible_party_policies
        }
      )
    end

    def store_transmit_events_with_errors(subject, _policies_by_subscriber)
      subject.transmit_events =
        policies_by_year.collect do |tax_year, policies|
          headers = {
            assistance_year: tax_year,
            correlation_id: SecureRandom.uuid,
            affected_policies: policies.map(&:eg_id)
          }
          posted_event = event('events.insurance_policies.posted', attributes: {}, headers: headers).success
          build_transmit_event(posted_event.name, posted_event.headers, @error_handler.error_messages)
        end
      subject.save
    end

    def publish_family_cv_payloads(subject, policies_by_year, cv3_payloads)
      subject.transmit_events =
        cv3_payloads.collect do |tax_year, payload|
          headers = {
            assistance_year: tax_year,
            correlation_id: SecureRandom.uuid,
            affected_policies: policies_by_year[tax_year].map(&:eg_id)
          }
          posted_event =
            event('events.insurance_policies.posted', attributes: { family: payload }, headers: headers).success

          posted_event_headers = posted_event.headers.dup
          posted_event.publish

          build_transmit_event(posted_event.name, posted_event_headers)
        end

      subject.save
      Success(subject)
    end

    def build_transmit_event(event_name, headers, errors = [])
      attrs = { name: event_name, headers: headers.to_json, status: :transmitted }
      attrs.merge(error_messages: errors, status: :errored) if errors.present?

      ::Integrations::Event.new(attrs)
    end
  end
end
