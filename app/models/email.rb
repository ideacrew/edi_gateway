# frozen_string_literal: true

# Encapsulates an email address.
class Email
  include Mongoid::Document
  store_in client: :edidb

  TYPES = %w(home work).freeze

  field :email_type, type: String
  field :email_address, type: String

  embedded_in :person, :inverse_of => :emails
end
