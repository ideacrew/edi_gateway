module Policies
  class Projector < Sequent::Projector
    manages_tables ::Policies::PolicyRecord, ::Policies::CoverageSpanRecord, ::Policies::CoverageSpanEnrolleeRecord

    on ::Policies::Events::PolicyCreated do |event|
      span = event.coverage_span
      create_record(
        ::Policies::PolicyRecord,
        {
          aggregate_id: event.aggregate_id,
          policy_identifier: event.policy_identifier,
          subscriber_hbx_id: event.subscriber_hbx_id,
          policy_start: span.coverage_start,
          policy_end: span.coverage_end,
          product_hios_id: event.product.hios_id,
          product_coverage_year: event.product.coverage_year,
          responsible_party_hbx_id: event.responsible_party_hbx_id
        }
      )
      coverage_span_record = create_record(
        ::Policies::CoverageSpanRecord,
        {
          policy_record_aggregate_id: event.aggregate_id,
          enrollment_id: span.enrollment_id,
          coverage_start: span.coverage_start,
          coverage_end: span.coverage_end,
          total_cost: span.total_cost,
          applied_aptc: span.applied_aptc,
          employer_assistance_amount: span.employer_assistance_amount,
          responsible_amount: span.responsible_amount
        }
      )
      if span.enrollees
        span.enrollees.each do |en|
          create_record(
            ::Policies::CoverageSpanEnrolleeRecord,
            {
              coverage_span_id: coverage_span_record.id,
              hbx_member_id: en.hbx_member_id,
              premium: en.premium,
              rate_schedule_date: en.rate_schedule_date,
              relationship: en.relationship,
              tobacco_usage: en.tobacco_usage
            }
          )
        end
      end
    end

    on ::Policies::Events::SpanAdded do |event|
      update_all_records(
        ::Policies::PolicyRecord,
        {aggregate_id: event.aggregate_id},
        {
          policy_start: event.policy_start,
          policy_end: event.policy_end
        }
      )
      span = event.coverage_span
      coverage_span_record = create_record(
        ::Policies::CoverageSpanRecord,
        {
          policy_record_aggregate_id: event.aggregate_id,
          enrollment_id: span.enrollment_id,
          coverage_start: span.coverage_start,
          coverage_end: span.coverage_end,
          total_cost: span.total_cost,
          applied_aptc: span.applied_aptc,
          employer_assistance_amount: span.employer_assistance_amount,
          responsible_amount: span.responsible_amount
        }
      )
      if span.enrollees
        span.enrollees.each do |en|
          create_record(
            ::Policies::CoverageSpanEnrolleeRecord,
            {
              coverage_span_id: coverage_span_record.id,
              hbx_member_id: en.hbx_member_id,
              premium: en.premium,
              rate_schedule_date: en.rate_schedule_date,
              relationship: en.relationship,
              tobacco_usage: en.tobacco_usage
            }
          )
        end
      end
    end
  end
end