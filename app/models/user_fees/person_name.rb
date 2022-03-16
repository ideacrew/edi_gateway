# frozen_string_literal: true

module UserFees
  class PersonName
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :member, class_name: 'UserFees::Member'

    field :first_name, type: String
    field :last_name, type: String

    def to_hash
      values = self.serializable_hash.deep_symbolize_keys.merge(id: id.to_s)
      AcaEntities::Ledger::Contracts::PersonNameContract.new.call(values).to_h
    end

    alias to_h to_hash
  end
end
