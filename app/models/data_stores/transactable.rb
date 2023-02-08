# frozen_string_literal: true

module DataStores
  # A single workflow event instance for transmission to an external service
  module Transactable
    # A list of valid status values.  Override defaults using initializer options
    # acked: acknowledged
    # completed: processing of the object finished
    # nacked: negative_acknowledged, an outside service completed processing and indicated an error
    # pending: awaiting processing
    DEFAULT_STATUS_KINDS = %i[
      acked
      completed
      denied
      errored
      excluded
      expired
      failed
      nacked
      pending
      submitted
      successful
      transmitted
    ].freeze

    extend ActiveSupport::Concern

    included do
      belongs_to :account, class_name: 'Accounts::Account'

      embeds_one :request_event, class_name: 'Integrations::Event'
      embeds_one :response_event, class_name: 'Integrations::Event'

      field :command_class_name, type: String

      field :acknowledged_at, type: DateTime
      field :status, type: Symbol

      # field :started_at, type: DateTime, default: -> { Time.now }
      field :completed_at, type: DateTime

      # delegate :started_at_timestamp, to: :request_event_timestamp
      # delegate :ended_at, to: :response_event,

      def initialize(args)
        super
        @status_kinds = options[:status_kinds] || DEFAULT_STATUS_KINDS
      end

      def status=(value)
        raise ArgumentError "must be one of: #{@status_kinds}" unless @status_kinds.includes?(value)

        write_attribute(:status, value)
      end

      def errors; end

      def exceptions; end
    end

    # add scopes to query requests event not triggered, response events not received
    class_methods do
      # scope :started_at, -> { ('request_event.timestamp': true) }
      # scope :valid?, -> { ('request_event.errors': true) }

      # scope :transactions_completed, -> { exists?('response_event.timestamp': false) }
    end
  end
end
