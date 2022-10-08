# frozen_string_literal: true

module Queries
  # Pull policies for a person
  class PersonAssociations
    def initialize(person)
      @person = person
    end

    def policies
      Policy.where(
        { "enrollees.m_id" =>
            { "$in" => @person.members.map(&:hbx_member_id) } }
      )
    end
  end
end
