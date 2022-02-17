# frozen_string_literal: true

module UserFee
  class TaxHousehold
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :policy, class_name: 'UserFee::Policy'

    field :aptc_amount_total, type: Money
  end
end
