# frozen_string_literal: true

module UserFees
  class Premium
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :enrolled_member, class_name: '::UserFees::EnrolledMember'

    field :insured_age, type: Integer
    field :amount, type: BigDecimal

    def to_hash
      values = self.serializable_hash.deep_symbolize_keys.merge(id: id.to_s)
      AcaEntities::Ledger::Contracts::PremiumContract.new.call(values).to_h
    end

    alias to_h to_hash
  end
end
