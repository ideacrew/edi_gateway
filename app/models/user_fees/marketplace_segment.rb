# frozen_string_literal: true

module UserFees
  class MarketplaceSegment
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :policy, class_name: '::UserFees::Policy'
    embeds_many :enrolled_members, class_name: '::UserFees::EnrolledMember', cascade_callbacks: true

    field :subscriber_hbx_id, type: String
    field :start_on, type: Date
    field :end_on, type: Date
    field :segment, type: String
    field :total_premium_amount, type: BigDecimal
    field :total_premium_responsibility_amount, type: BigDecimal

    def to_hash
      values = self.serializable_hash.deep_symbolize_keys.merge(id: id.to_s)
      AcaEntities::Ledger::Contracts::MarketplaceSegmentContract.new.call(values).to_h
    end

    alias to_h to_hash
  end
end
