module Queries
  class PolicyAssociations
    def initialize(policy)
      @policy = policy
    end

    def people
      Person.where({
        "members.hbx_member_id" =>
        { "$in" => @policy.enrollees.map(&:m_id) }
      })
    end

    def responsible_person
      return nil if @policy.responsible_party_id.nil?
      Person.where("responsible_parties._id" => Moped::BSON::ObjectId.from_string(@policy.responsible_party_id)).first
    end
  end
end
