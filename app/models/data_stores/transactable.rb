# frozen_string_literal: true

module DataStores
  # A list of valid status values.  Override defaults using initializer options
  # acked: acknowledged
  # completed: processing of the object finished
  # nacked: negative_acknowledged, an outside service completed processing and indicated an error
  # pending: awaiting processing
  DEFAULT_STATUS_KINDS = %i[
    acked
    completed
    created
    denied
    errored
    excluded
    expired
    failed
    nacked
    noop
    pending
    processing
    submitted
    successful
    transmitted
  ].freeze

  # A single workflow event instance for transmission to an external service
  module Transactable
    extend ActiveSupport::Concern

    included do
      # belongs_to :account, class_name: 'Accounts::Account', optional: true

      embeds_one :request_event, as: :eventable, class_name: '::Integrations::Event', cascade_callbacks: true
      embeds_one :response_event, as: :eventable, class_name: '::Integrations::Event', cascade_callbacks: true
      embeds_many :transmit_events, as: :eventable, class_name: '::Integrations::Event', cascade_callbacks: true

      field :acknowledged_at, type: DateTime
      field :status, type: Symbol

      # # TODO: submitted when triggered event to enroll
      # # errored/completed up on processing the response from enroll

      # # field :started_at, type: DateTime, default: -> { Time.now }
      # # field :completed_at, type: DateTime # TODO: make this a scope

      # # delegate :started_at_timestamp, to: :request_event_timestamp
      # # delegate :ended_at, to: :response_event,

      def status=(value)
        # raise ArgumentError "must be one of: #{@status_kinds}" unless @status_kinds.includes?(value)
        write_attribute(:status, value)
      end

      # def errors; end # TODO: create a scope
      # def exceptions; end
    end

    # add scopes to query requests event not triggered, response events not received
    # class_methods do
    #   # scope :started_at, -> { ('request_event.timestamp': true) }
    #   # scope :valid?, -> { ('request_event.errors': true) }
    #   # scope :transactions_completed, -> { exists?('response_event.timestamp': false) }
    # end
  end
end
