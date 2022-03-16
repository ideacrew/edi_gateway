# frozen_string_literal: true

module UserFees
  # An organization offering insurance contracts
  class Insurer
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :policies, class_name: 'UserFees::Policy'

    field :hios_id, type: String
    field :name, type: String
    field :description, type: String

    def to_hash
      values = self.serializable_hash.deep_symbolize_keys.merge(id: id.to_s)
      AcaEntities::Ledger::Contracts::InsurerContract.new.call(values).to_h
    end

    alias to_h to_hash
  end
end
