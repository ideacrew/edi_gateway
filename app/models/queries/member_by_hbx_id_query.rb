# frozen_string_literal: true

module Queries
  # Query to look for person by hbx id
  class MemberByHbxIdQuery
    def initialize(dcas_no)
      @dcas_no = dcas_no
    end

    def execute
      person = Person.unscoped.where("members.hbx_member_id" => @dcas_no).first
      return(nil) if person.blank?

      person.nil? ? nil : (person.members.detect { |m| m.hbx_member_id == @dcas_no })
    end
  end
end
