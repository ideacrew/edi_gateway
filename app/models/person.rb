# frozen_string_literal: true

# Represents a person as a collection of contact info, members, and responsible parties.
class Person
  include Mongoid::Document
  store_in client: :edidb

  field :name_pfx, type: String, default: ""
  field :name_first, type: String
  field :name_middle, type: String, default: ""
  field :name_last, type: String
  field :name_sfx, type: String, default: ""
  field :name_full, type: String

  field :authority_member_id, type: String, default: nil

  embeds_many :members

  embeds_many :responsible_parties

  embeds_many :addresses, :inverse_of => :person

  embeds_many :emails, :inverse_of => :person

  embeds_many :phones, :inverse_of => :person

  index({ name_last:  1 })
  index({ name_first: 1 })
  index({ name_last: 1, name_first: 1 })
  index({ name_first: 1, name_last: 1 })

  index({ "members.hbx_member_id" => 1 })
  index({ "members.ssn" => 1 })
  index({ "members.dob" => 1 })
  index({ "authority_member_id" => 1 })

  def authority_member
    return self.members.first if members.length < 2

    members.detect { |m| m.hbx_member_id == self.authority_member_id }
  end

  def self.find_for_member_id(m_id)
    Queries::PersonByHbxIdQuery.new(m_id).execute
  end

  def policies
    query_proxy.policies
  end

  def primary_address
    address = self.addresses[0]
    raise 'Primary address missing' if address.nil?
  end

  private

  def query_proxy
    @query_proxy ||= Queries::PersonAssociations.new(self)
  end
end
