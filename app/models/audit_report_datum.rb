# frozen_string_literal: true

# This class represents single run of the report,
# and helps connect all the subsequent subscriber child records
class AuditReportDatum
  include Mongoid::Document
  include Mongoid::Timestamps

  field :hios_id, type: String
  field :subscriber_id, type: String
  field :status, type: String
  field :payload, type: String
  field :report_type, type: String
  field :year, type: Integer

  embeds_many :ard_policies, cascade_callbacks: true

  index({ hios_id: 1, status: 1 })
  index({ subscriber_id: 1, status: 1 })
end
