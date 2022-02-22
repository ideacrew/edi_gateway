# frozen_string_literal: true

module UserFees
  class Premium
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :enrolled_member, class_name: '::UserFees::EnrolledMember'

    field :insured_age, type: Integer
    field :amount, type: BigDecimal
  end
end
