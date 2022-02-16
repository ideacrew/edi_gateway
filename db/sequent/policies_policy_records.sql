CREATE TABLE policies_policy_records%SUFFIX% (
  id BIGSERIAL PRIMARY KEY,
  aggregate_id varchar(1024) UNIQUE NOT NULL,
  policy_identifier varchar(1024) NOT NULL,
  policy_start timestamp without time zone NOT NULL,
  policy_end timestamp without time zone,
  policy_expires timestamp without time zone,
  subscriber_hbx_id varchar(1024) NOT NULL,
  product_hios_id varchar(1024) NOT NULL,
  product_coverage_year varchar(1024) NOT NULL,
  responsible_party_hbx_id varchar(1024)
);

CREATE INDEX policies_policy_records_agg_id%SUFFIX% ON policies_policy_records%SUFFIX% USING btree (aggregate_id);
CREATE INDEX policies_policy_records_pi_id%SUFFIX% ON policies_policy_records%SUFFIX% USING btree (policy_identifier);
CREATE INDEX policies_policy_records_sub_id%SUFFIX% ON policies_policy_records%SUFFIX% USING btree (subscriber_hbx_id);
CREATE INDEX policies_policy_records_product_search%SUFFIX% ON policies_policy_records%SUFFIX% USING btree (product_hios_id, product_coverage_year);
