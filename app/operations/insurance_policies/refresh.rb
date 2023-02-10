# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module InsurancePolicies
  # this will capture all the exceptions occurred during the process
  class ErrorHandler
    attr_reader :errors

    def initialize
      @errors = []
    end

    def capture_exception
      yield
    rescue StandardError => e
      @errors << e.to_s
    end
  end

  # Persist contract holder sync job with subjects into the database
  class Refresh
    send(:include, Dry::Monads[:result, :do])

    attr_reader :error_handler

    def call(params)
      values       = yield validate(params)
      sync_job     = yield create_sync_job(values)
      query        = yield create_new_query(values)
      _policies    = yield persist_subscriber_policies(sync_job, query)
      _rp_policies = yield persist_responsible_party_policies(sync_job, query)
      sync_job     = yield close_sync_job(sync_job)

      Success(sync_job)
    end

    private

    def validate(params)
      return Failure("start_time is required") unless params[:start_time].present?
      return Failure("end_time is required") unless params[:end_time].present?

      @error_handler = ErrorHandler.new

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
        @error_handler.capture_exception do
          subject_create_or_update({
                                     contract_holder_sync_job: sync_job,
                                     primary_person_hbx_id: result["_id"],
                                     subscriber_policies: result["enrolled_policies"]
                                   })
        end
      end

      Success(true)
    end

    def persist_responsible_party_policies(sync_job, policy_query)
      policy_query.policies_by_responsible_party do |result|
        @error_handler.capture_exception do
          responsible_person = responsible_party_person_for(result['_id'])
          raise "unable to find person record for with responsible party #{result['_id']}" unless responsible_person

          subject_create_or_update({
                                     contract_holder_sync_job: sync_job,
                                     primary_person_hbx_id: responsible_person.authority_member_id,
                                     responsible_party_policies: result["enrolled_policies"]
                                   })
        end
      end

      Success(true)
    end

    def subject_create_or_update(options)
      response = DataStores::ContractHolderSubjects::CreateOrUpdate.new.call(options)
      raise response.failure if response.failure?
    end

    def close_sync_job(sync_job)
      status = :transmitted
      status = :errored if @error_handler.errors.present?
      sync_job.update(status: status, error_messages: @error_handler.errors)

      Success(sync_job)
    end

    def responsible_party_person_for(responsible_party_id)
      Person.where(:'responsible_parties._id' => responsible_party_id).first
    end
  end
end

#
# params: datetime range
#     calculate_date_range
#     start_date max of the parameter start date and refresh end date
#     end_date is min of the parameter end date and datetime now
#        if end date is less than refresh end date (nothing to do)

#  query gluedb for policies and primary person with given datetime range
#    - query for policies create or updated

#  persist as transactions in refresh table (by primary person)
#  fire events to request enroll family cv for each primary applicant
#  query glue policies with date time range
#  trigger enroll refresh for each family
