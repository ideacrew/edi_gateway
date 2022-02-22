# frozen_string_literal: true

module UserFees
  class PersonName
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :member, class_name: 'UserFees::Member'

    field :first_name, type: String
    field :last_name, type: String
  end
end
