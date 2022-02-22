# frozen_string_literal: true

module UserFees
  class Product
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :policy, class_name: '::UserFees::Policy'

    field :name, type: String
    field :description, type: String
    field :hbx_qhp_id, type: String
    field :effective_year, type: Integer
    field :kind, type: String
  end
end
