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
  end
end
