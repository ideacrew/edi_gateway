module Policies
  class PolicyRecord < Sequent::ApplicationRecord
    self.table_name = "policies_policy_records"

    has_many :coverage_span_records, class_name: "::Policies::CoverageSpanRecord", primary_key: "aggregate_id", foreign_key: "policy_record_aggregate_id"
  end
end