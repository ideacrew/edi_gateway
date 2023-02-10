# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module DataStores
  module ContractHolderSubjects
    # Operation to create or update ContractHolderSubjects
    class CreateOrUpdate
      send(:include, Dry::Monads[:result, :do])
      include EventSource::Command

      def call(params)
        values  = yield validate(params)
        subject = yield create_or_update_subject(values)
        output  = yield publish_event(subject)

        Success(subject)
      end

      private

      def validate(params)
        errors = []
        errors << "contract_holder_sync_job required" unless params[:contract_holder_sync_job]
        errors << "primary hbx id" unless params[:primary_person_hbx_id]
        if params[:subscriber_policies].blank? && params[:responsible_party_policies].blank?
          errors << "at least one of subscriber or responsible party policies required"
        end

        errors.present? ? Failure(errors) : Success(params)
      end

      def create_or_update_subject(values)
        subject = find_subject(values)
        subject ||= values[:contract_holder_sync_job].subjects.build(primary_person_hbx_id: values[:primary_person_hbx_id])
        subject.subscriber_policies = values[:subscriber_policies]
        subject.responsible_party_policies = values[:responsible_party_policies]

        if subject.save
          Success(subject)
        else
          Failure(subject.errors.to_h)
        end
      end

      def publish_event(subject)
        return Success(subject) if subject.request_event&.transmitted?

        event_name = "events.families.find_by_requested"
        event_payload = { person_hbx_id: subject.primary_person_hbx_id }.to_json
        event = event(event_name, attributes: event_payload)
        event.success.publish
        logger.info("published family refresh event for #{subject.primary_person_hbx_id} at #{DateTime.now}")
        persist_request_event(subject, event_name, event_payload)
        Success("published family refresh event for #{subject.primary_person_hbx_id} at #{DateTime.now}")
      rescue StandardError => e
        logger.info("unable to publish family refresh for #{subject.primary_person_hbx_id} due to #{e.inspect}")
        persist_request_event(subject, event_name, event_payload, [e.to_s])
        Failure("unable to publish family refresh for #{subject.primary_person_hbx_id} due to #{e.inspect}")
      end

      def persist_request_event(subject, event_name, event_payload, errors = [])
        request_event = Integrations::Events::Build.new.call({
                                                               name: event_name,
                                                               body: event_payload,
                                                               errors: errors
                                                             }).success

        subject.update(request_event: request_event)
      end

      def find_subject(values)
        sync_job = values[:contract_holder_sync_job]
        sync_job.subjects.by_primary_hbx_id(values[:primary_person_hbx_id]).first
      end

      def logger
        return @logger if defined? @logger

        @logger = Logger.new("#{Rails.root}/log/subject_create_or_update_#{Date.today.strftime('%Y_%m_%d')}.log")
      end
    end
  end
end
