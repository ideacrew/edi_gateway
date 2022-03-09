module Policies
  class CoverageSpanEnrolleeRecord < Sequent::ApplicationRecord
    self.table_name = "policies_coverage_span_enrollee_records"

    belongs_to :coverage_span_record, class_name: "::Policies::CoverageSpanRecord", foreign_key: "coverage_span_id"
  end
end