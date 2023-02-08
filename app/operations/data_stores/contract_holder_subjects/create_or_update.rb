# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module DataStores
  module ContractHolderSubjects
    # Operation to create Enrollments.
    class CreateOrUpdate
      send(:include, Dry::Monads[:result, :do])

      def call(params)
        values   = yield validate(params)
        sync_job = yield find_contract_holder_sync_job(values)
        subject  = yield create_or_update_subject(sync_job, values)

        Success(subject)
      end

      private

      def validate(params)
        errors = []
        errors << "contract_holder_sync_job required" unless params[:contract_holder_sync_job_id]
        errors << "primary hbx id" unless params[:primary_person_hbx_id]
        if params[:subscriber_policies].blank? && params[:responsible_party_policies].blank?
          errors << "at least one of subscriber or responsible party policies required"
        end

        errors.present? ? Failure(errors) : Success(params)
      end

      def create_or_update_subject(sync_job, values)
        subject = find_subject(sync_job, values)
        subject ||= sync_job.subjects.build(primary_person_hbx_id: values[:primary_person_hbx_id])
        subject.subscriber_policies = values[:subscriber_policies]
        subject.responsible_party_policies = values[:responsible_party_policies]

        if subject.save
          Success(subject)
        else
          Failure(subject.errors.to_h)
        end
      end

      def find_contract_holder_sync_job(values)
        sync_job = DataStores::ContractHolderSyncJob.find(values[:contract_holder_sync_job_id])
        return Failure("unable to find sync job with id #{values[:contract_holder_sync_job_id]}") unless sync_job

        Success(sync_job)
      end

      def find_subject(sync_job, values)
        sync_job.subjects.by_primary_hbx_id(values[:primary_person_hbx_id]).first
      end
    end
  end
end
