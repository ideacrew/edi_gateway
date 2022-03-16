# frozen_string_literal: true

module UserFees
  class TaxHousehold
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :insurance_coverage, class_name: '::UserFees::InsuranceCoverage'

    field :assistance_year, type: Integer
    field :exchange_assigned_id, type: String
    field :aptc_amount, type: BigDecimal
    field :csr, type: Integer
    field :start_on, type: Date
    field :end_on, type: Date

    def to_hash
      values = self.serializable_hash.deep_symbolize_keys.merge(id: id.to_s)
      AcaEntities::Ledger::Contracts::TaxHouseholdContract.new.call(values).to_h
    end

    alias to_h to_hash
  end
end
