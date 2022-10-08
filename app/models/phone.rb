# frozen_string_literal: true

class Phone
  include Mongoid::Document


  TYPES = %W(home work mobile fax)

  field :phone_type, type: String
  field :phone_number, type: String
  field :extension, type: String, default: ""
  field :primary, type: Boolean
  field :country_code, type: String, default: ""
  field :area_code, type: String, default: ""
  field :full_phone_number, type: String, default: ""


  embedded_in :person, :inverse_of => :phones
end
