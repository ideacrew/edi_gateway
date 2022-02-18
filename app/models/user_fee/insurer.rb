# frozen_string_literal: true

module UserFee
  class Insurer
    include Mongoid::Document
    include Mongoid::Timestamps

    has_many :policies, class_name: 'UserFee::Policy'

    field :hios_id, type: String
    field :name, type: String
    field :description, type: String
  end
end
