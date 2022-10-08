# frozen_string_literal: true

class Member
  include Mongoid::Document
  store_in client: :edidb

  # auto_increment :_id, seed: 9999

  field :_id, type: Integer
  field :hbx_member_id, type: String      # Enterprise-level unique ID for this person

  field :e_person_id, type: String        # Elibility system transaction-level foreign key
  field :e_concern_role_id, type: String  # Eligibility system 'unified person' foreign key
  field :aceds_id, type: Integer          # Medicaid system foreign key

  field :import_source, type: String      # e.g. :b2b_gateway, :eligibility_system
  field :imported_at, type: DateTime

  field :dob, type: Date
  field :death_date, type: Date
  field :ssn, type: String
  field :gender, type: String
  field :ethnicity, type: String, default: ""
  field :race, type: String, default: ""
  field :birth_location, type: String, default: ""
  field :marital_status, type: String, default: ""
  field :hbx_role, type: String, default: ""

  field :citizen_status, type: String, default: 'us_citizen'
  field :is_state_resident, type: Boolean, default: true
  field :is_incarcerated, type: Boolean, default: false
  field :is_disabled, type: Boolean, default: false
  field :is_pregnant, type: Boolean, default: false

  field :hlh, as: :tobacco_use_code, type: String, default: "unknown"
  field :lui, as: :language_code, type: String

  embedded_in :person

  def person
    Queries::PersonByHbxIdQuery.new(m_id).execute
  end

  def member
    Queries::MemberByHbxIdQuery.new(m_id).execute
  end
end
