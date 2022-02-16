CREATE TABLE policies_coverage_span_enrollee_records%SUFFIX% (
  id BIGSERIAL PRIMARY KEY,
  coverage_span_id BIGSERIAL NOT NULL,
  hbx_member_id varchar(1024) NOT NULL,
  relationship varchar(256) NOT NULL,
  rate_schedule_date timestamp without time zone,
  premium numeric(20,4) NOT NULL,
  tobacco_usage varchar(3) NOT NULL,
  CONSTRAINT pcser_pcsr_id_fk%SUFFIX% FOREIGN KEY (coverage_span_id)
    REFERENCES policies_coverage_span_records%SUFFIX% (id)
);

CREATE INDEX pcser_coverage_span_id%SUFFIX% ON policies_coverage_span_enrollee_records%SUFFIX% USING btree (coverage_span_id);
CREATE INDEX pcser_hbx_member_id%SUFFIX% ON policies_coverage_span_enrollee_records%SUFFIX% USING btree (hbx_member_id);
