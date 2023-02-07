# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module InsurancePolicies
  # Queries glue policies by subscriber and responsible party
  class GluePolicyQuery
    def initialize(start_time, end_time)
      @start_time = start_time
      @end_time = end_time
    end

    # rubocop:disable Metrics/MethodLength, Layout/LineLength
    def by_subscriber
      policies_by_subscriber = Policy.collection.raw_aggregate([
                                                                 { "$match" => {
                                                                   :created_at => { "$gte" => @start_time, "$lte" => @end_time },
                                                                   :responsible_party_id => { "$exists" => false }
                                                                 } },
                                                                 { "$unwind" => "$enrollees" },
                                                                 { "$match" => { "enrollees.rel_code" => "self" } },
                                                                 { "$project" => { "cancelled" => {
                                                                                     "$eq" => ["$enrollees.coverage_start", "$enrollees.coverage_end"]
                                                                                   },
                                                                                   "subscriber_id" => "$enrollees.m_id", "eg_id" => "$eg_id" } },
                                                                 { "$match" => { "cancelled" => false } },
                                                                 { "$group" => {
                                                                   "_id" => "$subscriber_id",
                                                                   "enrolled_policies" => { "$addToSet" => "$eg_id" }
                                                                 } }
                                                               ])

      policies_by_subscriber.each do |_record|
        yield
      end
    end

    def by_responsible_party
      responsible_party_policies = Policy.collection.raw_aggregate([
                                                                     { "$match" => {
                                                                       :created_at => { "$gte" => @start_time,
                                                                                        "$lte" => @end_time },
                                                                       :responsible_party_id => { "$exists" => true }
                                                                     } },
                                                                     { "$unwind" => "$enrollees" },
                                                                     { "$match" => { "enrollees.rel_code" => "self" } },
                                                                     { "$project" => { "cancelled" => {
                                                                                         "$eq" => ["$enrollees.coverage_start", "$enrollees.coverage_end"]
                                                                                       },
                                                                                       "subscriber_id" => "$responsible_party_id", "eg_id" => "$eg_id" } },
                                                                     { "$match" => { "cancelled" => false } },
                                                                     { "$group" => {
                                                                       "_id" => "$subscriber_id",
                                                                       "enrolled_policies" => { "$addToSet" => "$eg_id" }
                                                                     } }
                                                                   ])

      responsible_party_people(responsible_party_policies)
      responsible_party_policies.each do |_record|
        yield
      end
    end
    # rubocop:enable Metrics/MethodLength, Layout/LineLength

    def responsible_party_people(responsible_party_policies)
      return @responsible_party_people if defined? @responsible_party_people

      responsible_people = Person.where(:'responsible_parties._id'.in => responsible_party_policies.collect do |record|
                                                                           record['_id']
                                                                         end)
      @responsible_party_people = responsible_people.each_with_object({}) do |person, data|
        person.responsible_parties.each do |responsible_party|
          data[responsible_party.id] = person.authority_member_id
        end
      end
    end
  end
end
