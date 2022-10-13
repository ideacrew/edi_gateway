# frozen_string_literal: true

module Queries
  # Pull policies for a person
  class PersonAssociations
    def initialize(person)
      @person = person
    end

    def policies
      res_ids = @person.responsible_parties.map { |res| res.id.to_s }
      Policy.where("$or" => [
                     { "enrollees.m_id" => { "$in" => @person.members.map(&:hbx_member_id) } },
                     { :responsible_party_id.in => res_ids }
                   ])
    end
  end
end
