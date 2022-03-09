# frozen_string_literal: true

module GluedbReports
  # Create a report on the 'ideal' gluedb spans mapping.
  class CreateSpanReport
    send(:include, Dry::Monads[:result, :do])

    def call(params)
      validated_params = yield validate_params(params)
      with_field_header = yield build_field_headers(params)
      create_span_report_records(with_field_header)
    end

    def validate_params(params)
      # TODO: Make sure this is a csv file or at least an appendable
      Success(params)
    end

    def build_field_headers(csv)
      csv << [
        "HBX Enrollment ID",
        "GlueDB Enrollment Group ID",
        "Responsible Party ID",
        "Subscriber ID",
        "Member ID",
        "Relationship",
        "Coverage Start",
        "Coverage End",
        "Policy Start",
        "Policy End",
        "Member Premium",
        "Tobacco Use",
        "Total Premium",
        "Applied APTC",
        "Responsible Amount",
        "Rating Area",
        "Plan HIOS ID",
        "Plan Coverage Year"
      ]
      Success(csv)
    end

    def create_span_report_records(csv)
      Policies::CoverageSpanEnrolleeRecord.all.preload(:coverage_span_record => :policy_record).each do |rec|
        csv << [
          rec.coverage_span_record.enrollment_id,
          rec.coverage_span_record.policy_record.policy_identifier,
          rec.coverage_span_record.policy_record.responsible_party_hbx_id,
          rec.coverage_span_record.policy_record.subscriber_hbx_id,
          rec.hbx_member_id,
          rec.relationship,
          rec.coverage_span_record.coverage_start,
          rec.coverage_span_record.coverage_end,
          rec.coverage_span_record.policy_record.policy_start,
          rec.coverage_span_record.policy_record.policy_end,
          rec.premium,
          rec.tobacco_usage,
          rec.coverage_span_record.total_cost,
          rec.coverage_span_record.applied_aptc,
          rec.coverage_span_record.responsible_amount,
          rec.coverage_span_record.policy_record.rating_area,
          rec.coverage_span_record.policy_record.product_hios_id,
          rec.coverage_span_record.policy_record.product_coverage_year
        ]
      end
      Success(:ok)
    end
  end
end