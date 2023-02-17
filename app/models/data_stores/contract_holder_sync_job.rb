# frozen_string_literal: true

module DataStores
  # A model to persist a DataStore synchronization job, its current state and transactions
  class ContractHolderSyncJob
    include Mongoid::Document
    include Mongoid::Timestamps

    has_many :subjects, class_name: 'DataStores::ContractHolderSubject'

    field :job_id, type: String, default: -> { SecureRandom.uuid }

    # Time boundary parameters for the job
    field :time_span_start, type: DateTime
    field :time_span_end, type: DateTime

    # State for the job
    field :status, type: Symbol, default: :created
    field :start_at, type: DateTime, default: -> { Time.now }
    field :end_at, type: DateTime
    field :error_messages, type: Array, default: -> { [] }

    index({ job_id: 1 })
    index({ time_span_end: -1 })
    index({ status: 1 })

    # FIXME: test following scope
    scope :latest_job, -> { where(:status.ne => :noop).order_by(time_span_end: -1) }
    scope :exceptions, -> { exists?('subjects.errors': true) }

    validate :validate_timespan

    # All subject_entries successfully processed
    def is_complete?
      end_at.nil? == false
    end

    def end_at=(value = Time.now)
      write_attribute(:end_at, value)
    end

    def latest_time_span_end
      self.class.latest_job.first&.time_span_end
    end

    private

    # Guard for start dates in the future and those that precede a prior sync operation
    def validate_time_span_start
      start_time = [time_span_start, Time.now, latest_time_span_end].compact.min

      write_attribute(:time_span_start, start_time)
    end

    # Guard for end dates in the future that if persisted will result in time gaps due to
    # time_span_start validation
    def validate_time_span_end
      end_time = [[time_span_end, Time.now].min, time_span_start].max

      write_attribute(:time_span_end, end_time)
    end

    def validate_timespan
      validate_time_span_start
      validate_time_span_end
      return true unless time_span_start == time_span_end

      self.end_at = start_at
      write_attribute(:status, :noop)
    end
  end
end
