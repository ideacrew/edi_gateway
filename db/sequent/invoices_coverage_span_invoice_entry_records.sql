CREATE TABLE invoices_coverage_span_invoice_entry_records%SUFFIX% (
  id BIGSERIAL PRIMARY KEY,
  aggregate_id varchar(1024) NOT NULL,
  product_invoice_aggregate_id varchar(1024) NOT NULL,
  policy_aggregate_id varchar(1024) NOT NULL,
  coverage_span_id BIGSERIAL NOT NULL,
  billed_individual_hbx_id varchar(1024) NOT NULL,
  billing_interval_start timestamp without time zone NOT NULL,
  billing_interval_end timestamp without time zone NOT NULL,
  coverage_start timestamp without time zone NOT NULL,
  coverage_end timestamp without time zone NOT NULL,
  total_cost numeric(20,4) NOT NULL,
  responsible_amount numeric(20,4) NOT NULL,
  applied_aptc numeric(20,4)
);

CREATE INDEX invoices_coverage_span_invoice_entry_record_agg_id%SUFFIX% ON invoices_coverage_span_invoice_entry_records%SUFFIX% USING btree (aggregate_id);
CREATE INDEX invoices_coverage_span_invoice_entry_record_pi_agg_id%SUFFIX% ON invoices_coverage_span_invoice_entry_records%SUFFIX% USING btree (product_invoice_aggregate_id);