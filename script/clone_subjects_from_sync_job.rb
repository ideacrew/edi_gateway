# frozen_string_literal: true

# clone subjects which are missing response events into a new sync job
class CloneSubjectsFromSyncJob
  attr_reader :source_job

  def initialize(source_job)
    @source_job = source_job
  end

  def clone_failed_subjects
    subjects = source_job.subjects.exists(rsponse_event: false)
    p "found #{subjects.count} subjects without response events"

    new_job = create_new_sync_job
    subjects.each do |subject|
      attributes = {
        contract_holder_sync_job: new_job,
        primary_person_hbx_id: subject.primary_person_hbx_id,
        subscriber_policies: subject.subscriber_policies,
        responsible_party_policies: subject.responsible_party_policies
      }
      ::DataStores::ContractHolderSubjects::CreateOrUpdate.new.call(attributes)
    end
  end

  def create_new_sync_job
    ::DataStores::ContractHolderSyncJob.create({
                                                 start_time: source_job.time_span_start,
                                                 end_time: source_job.time_span_end,
                                                 status: :processing,
                                                 source_job_id: source_job.job_id
                                               })
  end
end
