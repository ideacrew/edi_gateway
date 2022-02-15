module Policies
  module Commands
    class CreatePolicy < Sequent::Command
      attrs({
        policy_identifier: String,
        subscriber_hbx_id: String,
        coverage_span: ::Policies::ValueObjects::CoverageSpan,
        sponsor: ::Policies::ValueObjects::Sponsor,
        product: ::Policies::ValueObjects::Product,
        responsible_party_hbx_id: String
      })

      validates_presence_of :subscriber_hbx_id
      validates_presence_of :policy_identifier
      validates_presence_of :coverage_span
      validates_with(
        ActiveRecord::Validations::AssociatedValidator,
        attributes: :coverage_span
      )

      def self.create(policy_id, subscriber_hbx_id, span, sponsor, product, responsible_party_hbx_id)
        aggregate_id = "::Policies::Policy__#{policy_id}"
        self.new({
          aggregate_id: aggregate_id,
          policy_identifier: policy_id,
          subscriber_hbx_id: subscriber_hbx_id,
          coverage_span: span,
          sponsor: sponsor,
          product: product,
          responsible_party_hbx_id: responsible_party_hbx_id
        })
      end
    end
  end
end