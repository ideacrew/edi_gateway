module Policies
  module Events
    class PolicyCreated < Sequent::Event
      attrs({
        policy_identifier: String,
        subscriber_hbx_id: String,
        sponsor: ::Policies::ValueObjects::Sponsor,
        product: ::Policies::ValueObjects::Product,
        coverage_span: ::Policies::ValueObjects::CoverageSpan,
        responsible_party_hbx_id: String,
        rating_area: String
      })
    end

    class SpanAdded < Sequent::Event
      attrs({
        policy_start: DateTime,
        policy_end: DateTime,
        coverage_span: ::Policies::ValueObjects::CoverageSpan
      })
    end
  end
end