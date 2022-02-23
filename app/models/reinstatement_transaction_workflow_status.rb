# frozen_string_literal: true

# Tracks the status and workflow of an 834 reinstatement transaction.
class ReinstatementTransactionWorkflowStatus
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :inbound_834_transaction

  field :policy_database_status, type: String
  field :enrollment_database_status, type: String

  field :policy_database_correlation_id, type: String
  field :enrollment_database_correlation_id, type: String
end
