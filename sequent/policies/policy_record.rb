module Policies
  class PolicyRecord < Sequent::ApplicationRecord
    self.table_name = "policies_policy_records"

    has_many :coverage_span_records, class_name: "::Policies::CoverageSpanRecord", primary_key: "aggregate_id", foreign_key: "policy_record_aggregate_id"

    def self.in_billing_interval_range_with_product(
      product_hios_id,
      product_coverage_year,
      billing_interval_start,
      billing_interval_end
    )
      PolicyRecord.where({
        product_hios_id: product_hios_id,
        product_coverage_year: product_coverage_year
      }).where(
        arel_table[:policy_start].lteq(billing_interval_end)
      ).where(
        "(policy_end is NULL OR policy_end >= ?)",
        billing_interval_start
      )
    end
  end
end