CREATE TABLE invoices_product_invoice_records%SUFFIX% (
  id BIGSERIAL PRIMARY KEY,
  aggregate_id varchar(1024) UNIQUE NOT NULL,
  billing_period_start timestamp without time zone NOT NULL,
  billing_period_end timestamp without time zone NOT NULL,
  product_hios_id varchar(1024) NOT NULL,
  product_coverage_year varchar(1024) NOT NULL
);

CREATE INDEX invoices_product_invoice_records_agg_id%SUFFIX% ON invoices_product_invoice_records%SUFFIX% USING btree (aggregate_id);