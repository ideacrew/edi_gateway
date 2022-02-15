CREATE TABLE policies_coverage_span_records%SUFFIX% (
  id BIGSERIAL PRIMARY KEY,
  policy_record_aggregate_id varchar(1024) NOT NULL,
  enrollment_id varchar(1024) UNIQUE NOT NULL,
  coverage_start timestamp without time zone NOT NULL,
  coverage_end timestamp without time zone,
  total_cost numeric(20,4) NOT NULL,
  responsible_amount numeric(20,4) NOT NULL,
  applied_aptc numeric(20,4),
  employer_assistance_amount numeric(20,4),
  CONSTRAINT pcsr_ppr_agg_id_fk%SUFFIX% FOREIGN KEY (policy_record_aggregate_id)
    REFERENCES policies_policy_records%SUFFIX% (aggregate_id)
);

CREATE INDEX policies_coverage_span_records_eg_id%SUFFIX% ON policies_coverage_span_records%SUFFIX% USING btree (enrollment_id);
CREATE INDEX pcsr_ppr_agg_id%SUFFIX% ON policies_coverage_span_records%SUFFIX% USING btree (policy_record_aggregate_id);
