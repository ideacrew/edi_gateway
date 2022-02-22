# frozen_string_literal: true

module UserFees
  class TaxHousehold
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :customer_account, class_name: '::UserFees::CustomerAccount'

    field :aptc_amount, type: BigDecimal
    field :csr, type: Integer
    field :start_on, type: Date
    field :end_on, type: Date
  end
end
