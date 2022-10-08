# frozen_string_literal: true

module Queries
  # Query person by hbx id
  class PersonByHbxIdQuery
    def initialize(id)
      @id = id
    end

    def execute
      Person.unscoped.where({ "members.hbx_member_id" => @id }).first
    end
  end
end
