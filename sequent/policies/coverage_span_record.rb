module Policies
  class CoverageSpanRecord < Sequent::ApplicationRecord
    self.table_name = "policies_coverage_span_records"

    belongs_to :policy_record, class_name: "::Policies::PolicyRecord", primary_key: "aggregate_id", foreign_key: "policy_record_aggregate_id"
  end
end