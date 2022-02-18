# frozen_string_literal: true

module UserFee
  class Premium
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :enrolled_member, class_name: 'UserFee::EnrolledMember'

    field :insured_age, type: Integer
    field :amount, type: BigDecimal
  end
end
