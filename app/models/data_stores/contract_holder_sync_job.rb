# frozen_string_literal: true

module DataStores
  # A model to persist a DataStore synchronization job, its current state and transactions
  class ContractHolderSyncJob
    include Mongoid::Document
    include Mongoid::Timestamps

    has_many :subjects, class_name: 'DataStores::ContractHolderSubject'

    # Time boundary parameters for the job
    field :time_span_start, type: DateTime
    field :time_span_end, type: DateTime

    # State for the job
    field :status, type: Symbol
    field :started_at, type: DateTime, default: -> { Time.now }
    field :completed_at, type: DateTime
    field :error_messages, type: Array, default: -> { [] }

    index({ time_span_end: -1 })

    scope :lastest_end_date, -> { order_by(time_span_end: -1).first }
    scope :exceptions, -> { exists?('subjects.errors': true) }

    # All subject_entries successfully processed
    def is_complete?
      # code here
    end

    def exceptions; end

    private

    # Guard for start dates in the future and those that precede a prior sync operation
    def validate_time_span_start
      start_at = [[time_span_start, Time.now].min, lastest_end_date].max
      write_attribute(:time_span_start, start_at)
    end

    # Guard for end dates in the future that if persisted will result in time gaps due to
    # time_span_start validation
    def validate_time_span_end
      end_at = [end_at, Time.now].min
      write_attribute(:time_span_end, end_at)
    end

    def validate_time_span
      time_span_sttart < time_span_end
    end
  end
end
