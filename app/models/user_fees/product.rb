# frozen_string_literal: true

module UserFees
  class Product
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :policy, class_name: '::UserFees::Policy'

    field :name, type: String
    field :description, type: String
    field :hbx_qhp_id, type: String
    field :effective_year, type: Integer
    field :kind, type: String

    def to_hash
      values = self.serializable_hash.deep_symbolize_keys.merge(id: id.to_s)
      AcaEntities::Ledger::Contracts::ProductContract.new.call(values).to_h
    end

    alias to_h to_hash
  end
end
