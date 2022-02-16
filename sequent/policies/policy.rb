module Policies
  class Policy < Sequent::AggregateRoot
    def initialize(command)
      super(command.aggregate_id)
      apply(
        ::Policies::Events::PolicyCreated,
        {
          policy_identifier: command.policy_identifier,
          subscriber_hbx_id: command.subscriber_hbx_id,
          sponsor: command.sponsor,
          product: command.product,
          coverage_span: command.coverage_span,
          responsible_party_hbx_id: command.responsible_party_hbx_id
        }
      )
    end

    def add_span(command)
      new_policy_start = [command.coverage_span.coverage_start, @policy_start].min
      policy_end_date_choices = [command.coverage_span.coverage_end, @policy_end].compact
      new_policy_end = policy_end_date_choices.any? ? policy_end_date_choices.min : nil
      apply(
        ::Policies::Events::SpanAdded,
        {
          coverage_span: command.coverage_span,
          policy_start: new_policy_start,
          policy_end: new_policy_end
        }
      )
    end

    on ::Policies::Events::PolicyCreated do |event|
      @policy_identifier = event.policy_identifier
      @subscriber_hbx_id = event.subscriber_hbx_id
      @policy_start = event.coverage_span.coverage_start
      @policy_end = event.coverage_span.coverage_end
      @coverage_spans = [event.coverage_span]
      @sponsor = event.sponsor
      @product = event.product
      @responsible_party_hbx_id = event.responsible_party_hbx_id
    end

    on ::Policies::Events::SpanAdded do |event|
      @policy_start = event.policy_start
      @policy_end = event.policy_end
      @coverage_spans << event.coverage_span
    end
  end
end