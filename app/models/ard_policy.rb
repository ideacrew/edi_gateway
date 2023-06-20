# frozen_string_literal: true

# This class represents single run of the report,
# and helps connect all the subsequent subscriber child records
class ArdPolicy
  include Mongoid::Document
  include Mongoid::Timestamps

  field :policy_eg_id, type: String
  field :payload, type: String
  field :rcno_processed, type: Boolean, default: false

  embedded_in :audit_report_datum

  index({ rcno_processed: 1 })
end
