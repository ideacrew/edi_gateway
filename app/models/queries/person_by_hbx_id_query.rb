module Queries
  class PersonByHbxIdQuery
    def initialize(id)
      @id = id
    end

    def execute
      Person.unscoped.where({"members.hbx_member_id" => @id}).first
    end
  end
end