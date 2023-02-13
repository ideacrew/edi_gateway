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
        values = yield validate(params)
        subject = yield create_or_update_subject(values)

        Success(subject)
      end

      private

      def validate(params)
        errors = []
        errors << 'contract_holder_sync_job required' unless params[:contract_holder_sync_job]
        errors << 'primary hbx id' unless params[:primary_person_hbx_id]
        if params[:subscriber_policies].blank? && params[:responsible_party_policies].blank?
          errors << 'at least one of subscriber or responsible party policies required'
        end

        errors.present? ? Failure(errors) : Success(params)
      end

      def create_or_update_subject(values)
        subject = find_subject(values)
        subject ||=
          values[:contract_holder_sync_job].subjects.build(primary_person_hbx_id: values[:primary_person_hbx_id])
        subject.subscriber_policies = values[:subscriber_policies]
        subject.responsible_party_policies = values[:responsible_party_policies]

        subject.save ? Success(subject) : Failure(subject.errors.to_h)
      end

      def find_subject(values)
        sync_job = values[:contract_holder_sync_job]
        sync_job.subjects.by_primary_hbx_id(values[:primary_person_hbx_id]).first
      end
    end
  end
end
