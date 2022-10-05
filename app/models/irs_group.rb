# frozen_string_literal: true

class IrsGroup
  include Mongoid::Document
  include Mongoid::Timestamps

  field :hbx_id, type: String
  field :start_on, type: Date
  field :end_on, type: Date
  field :is_active, type: Boolean, default: true
  field :tax_houshold_id, type: BSON::ObjectId
  field :policy_id, type: String
end