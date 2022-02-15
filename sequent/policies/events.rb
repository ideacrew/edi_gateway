module Policies
  module Events
    class PolicyCreated < Sequent::Event
      attrs({
        policy_identifier: String,
        subscriber_hbx_id: String,
        sponsor: ::Policies::ValueObjects::Sponsor,
        product: ::Policies::ValueObjects::Product,
        coverage_span: ::Policies::ValueObjects::CoverageSpan,
        responsible_party_hbx_id: String
      })
    end
  end
end