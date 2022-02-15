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
  end
end