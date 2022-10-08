# frozen_string_literal: true

class Email
  include Mongoid::Document

  TYPES = %W(home work)

  field :email_type, type: String
  field :email_address, type: String

  validates_presence_of  :email_address
  validates_presence_of  :email_type, message: "Choose a type"
  validates_inclusion_of :email_type, in: TYPES, message: "Invalid type"

  embedded_in :person, :inverse_of => :emails
end
