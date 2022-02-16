module Policies
  class CoverageSpanRecord < Sequent::ApplicationRecord
    self.table_name = "policies_coverage_span_records"

    belongs_to :policy_record, class_name: "::Policies::PolicyRecord", primary_key: "aggregate_id", foreign_key: "policy_record_aggregate_id"
    has_many :coverage_span_enrollee_records, class_name: "::Policies::CoverageSpanEnrolleeRecord", foreign_key: "coverage_span_id"
  end
end