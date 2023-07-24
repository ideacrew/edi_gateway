# frozen_string_literal: true

# This class represents single run of the report,
# and helps connect all the subsequent subscriber child records
class ArdSegment
  include Mongoid::Document
  include Mongoid::Timestamps

  field :segment_id, type: String
  field :policy_eg_id, type: String
  field :en_hbx_id, type: String
  field :segment_start_date, type: Date
  field :payload, type: String
  field :rcno_processed, type: Boolean, default: false

  embedded_in :audit_report_datum, :inverse_of => :ard_segments

  index({ policy_eg_id: 1, en_hbx_id: 1, rcno_processed: 1 })
  index({ segment_id: 1 })
end
