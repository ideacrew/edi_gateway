# frozen_string_literal: true

module UserFees
  class Insurer
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :policies, class_name: 'UserFees::Policy'

    field :hios_id, type: String
    field :name, type: String
    field :description, type: String
  end
end
