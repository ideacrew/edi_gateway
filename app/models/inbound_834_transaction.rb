# frozen_string_literal: true

class Inbound834Transaction
  include Mongoid::Document
  include Mongoid::Timestamps

  mount_uploader :payload, PayloadUploader

  field :one_time_tag, type: String
  validates :one_time_tag, presence: true, allow_blank: false

  field :status, type: String, default: "received"

  # @!group Envelope Properties - Interchange
  field :interchange_control_number, type: String
  validates :interchange_control_number, presence: true, allow_blank: false

  field :interchange_sender_qualifier, type: String
  validates :interchange_sender_qualifier, presence: true, allow_blank: false

  field :interchange_sender_id, type: String
  validates :interchange_sender_id, presence: true, allow_blank: false

  field :interchange_receiver_qualifier, type: String
  validates :interchange_receiver_qualifier, presence: true, allow_blank: false

  field :interchange_receiver_id, type: String
  validates :interchange_receiver_id, presence: true, allow_blank: false

  field :interchange_timestamp, type: DateTime
  validates :interchange_timestamp, presence: true, allow_blank: false

  field :functional_group_count, type: Integer
  # @!endgroup

  # @!group Envelope Properties - Functional Group
  field :group_control_number, type: String
  validates :group_control_number, presence: true, allow_blank: false

  field :application_senders_code, type: String
  validates :application_senders_code, presence: true, allow_blank: false

  field :application_receivers_code, type: String
  validates :application_receivers_code, presence: true, allow_blank: false

  field :group_creation_timestamp, type: DateTime
  validates :group_creation_timestamp, presence: true, allow_blank: false

  field :transaction_set_count, type: Integer
  # @!endgroup

  # @!group Oracle B2B Properties
  field :b2b_message_id, type: String
  validates :b2b_message_id, presence: true, allow_blank: false

  field :b2b_created_at, type: DateTime
  validates :b2b_created_at, presence: true, allow_blank: false

  field :b2b_updated_at, type: DateTime
  validates :b2b_updated_at, presence: true, allow_blank: false

  field :b2b_business_message_id, type: String
  validates :b2b_business_message_id, presence: true, allow_blank: false

  field :b2b_protocol_message_id, type: String
  validates :b2b_protocol_message_id, presence: true, allow_blank: false

  field :b2b_in_trading_partner, type: String
  validates :b2b_in_trading_partner, presence: true, allow_blank: false

  field :b2b_out_trading_partner, type: String
  validates :b2b_out_trading_partner, presence: true, allow_blank: false

  field :b2b_message_status, type: String
  validates :b2b_message_status, presence: true, allow_blank: false

  field :b2b_direction, type: String
  validates :b2b_direction, presence: true, allow_blank: false

  field :b2b_document_type_name, type: String
  validates :b2b_document_type_name, presence: true, allow_blank: false

  field :b2b_document_protocol_name, type: String
  validates :b2b_document_protocol_name, presence: true, allow_blank: false

  field :b2b_document_protocol_version, type: String
  validates :b2b_document_protocol_version, presence: true, allow_blank: false

  field :b2b_document_definition, type: String
  validates :b2b_document_definition, presence: true, allow_blank: false

  field :b2b_conversation_id, type: String

  field :b2b_message_correlation_id, type: String
  # @!endgroup

  # Set only if payload parses correctly
  field :transaction_set_control_number, type: String
  field :transaction_set_reference_number, type: String

  index({ one_time_tag: 1 }, { unique: true })
end
