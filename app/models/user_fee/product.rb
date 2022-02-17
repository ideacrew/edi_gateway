# frozen_string_literal: true

module UserFee
  class Product
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :policy, class_name: 'UserFee::Policy'

    field :hbx_qhp_id, type: String
    field :effective_year, type: Integer
    field :name, type: String
    field :description, type: String
    field :kind, type: String
  end
end