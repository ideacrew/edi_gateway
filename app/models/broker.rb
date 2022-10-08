# frozen_string_literal: true

class Broker
  include Mongoid::Document
  store_in client: :edidb

  field :b_type, type: String
  field :name_pfx, as: :prefix, type: String, default: ""
  field :name_first, as: :given_name, type: String
  field :name_middle, type: String, default: ""
  field :name_last, as: :surname, type: String
  field :name_sfx, as: :suffix, type: String, default: ""
  field :name_full, type: String
  field :alternate_name, type: String, default: ""
  field :npn, type: String
  field :is_active, type: Boolean, default: true

  has_many :policies, inverse_of: :broker

  index({ :npn => 1 })
end
