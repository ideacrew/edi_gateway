# frozen_string_literal: true

class TaxHousehold
  include Mongoid::Document
  include Mongoid::Timestamps

  auto_increment :hbx_id, seed: 9999 

  field :allocated_aptc_in_cents, type: Integer, default: 0
  field :is_eligibility_determined, type: Boolean, default: false

  field :start_date, type: Date
  field :end_date, type: Date
  field :submitted_at, type: DateTime
  field :primary_applicant_id, type: BSON::ObjectId
end