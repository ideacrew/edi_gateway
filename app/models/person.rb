# frozen_string_literal: true

class Person
  include Mongoid::Document
  store_in client: :edidb

  field :name_pfx, type: String, default: ""
  field :name_first, type: String
  field :name_middle, type: String, default: ""
  field :name_last, type: String
  field :name_sfx, type: String, default: ""
  field :name_full, type: String

  embeds_many :members
  embeds_many :addresses, :inverse_of => :person
  embeds_many :phones, :inverse_of => :person
  embeds_many :emails, :inverse_of => :person
  embeds_many :responsible_parties

  index({ name_last:  1 })
  index({ name_first: 1 })
  index({ name_last: 1, name_first: 1 })
  index({ name_first: 1, name_last: 1 })

  index({ "members.hbx_member_id" => 1 })
  index({ "members.ssn" => 1 })
  index({ "members.dob" => 1 })

  def self.find_for_member_id(m_id)
    Queries::PersonByHbxIdQuery.new(m_id).execute
  end

  def policies
    query_proxy.policies
  end

  private

  def query_proxy
    @query_proxy ||= Queries::PersonAssociations.new(self)
  end
end