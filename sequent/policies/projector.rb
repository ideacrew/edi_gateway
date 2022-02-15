module Policies
  class Projector < Sequent::Projector
    manages_tables ::Policies::PolicyRecord, ::Policies::CoverageSpanRecord

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
          responsible_party_hbx_id: event.responsible_party_hbx_id
        }
      )
      create_record(
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
    end
  end
end