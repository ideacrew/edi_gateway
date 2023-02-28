# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module InsurancePolicies
  # Queries glue policies by subscriber and responsible party
  class GluePolicyQuery
    attr_reader :inclusion_policies

    def initialize(start_time, end_time)
      @start_time = start_time
      @end_time = end_time
    end

    def add_inclusion_policies(inclusion_policies)
      @inclusion_policies = inclusion_policies
    end

    def inclusion_list_subscriber_policies
      Policy.collection.aggregate(
        [
          {
            '$match' => {
              eg_id: {
                '$in' => inclusion_policies
              },
              responsible_party_id: {
                '$exists' => false
              }
            }
          },
          { '$unwind' => '$enrollees' },
          { '$match' => { 'enrollees.rel_code' => 'self' } },
          { '$project' => { 'subscriber_id' => '$enrollees.m_id', 'eg_id' => '$eg_id' } },
          { '$group' => { '_id' => '$subscriber_id', 'enrolled_policies' => { '$addToSet' => '$eg_id' } } }
        ]
      )
    end

    def group_by_subscriber_query
      return inclusion_list_subscriber_policies if inclusion_policies.present?

      Policy.collection.aggregate(
        [
          {
            '$match' => {
              updated_at: {
                '$gte' => @start_time,
                '$lte' => @end_time
              },
              responsible_party_id: {
                '$exists' => false
              }
            }
          },
          { '$unwind' => '$enrollees' },
          { '$match' => { 'enrollees.rel_code' => 'self' } },
          { '$project' => { 'subscriber_id' => '$enrollees.m_id', 'eg_id' => '$eg_id' } },
          { '$group' => { '_id' => '$subscriber_id', 'enrolled_policies' => { '$addToSet' => '$eg_id' } } }
        ]
      )
    end

    def policies_by_subscriber(&block)
      group_by_subscriber_query.each(&block)
    end

    def inclusion_list_responsible_party_policies
      Policy.collection.aggregate(
        [
          {
            '$match' => {
              eg_id: {
                '$in' => inclusion_policies
              },
              responsible_party_id: {
                '$exists' => true
              }
            }
          },
          { '$unwind' => '$enrollees' },
          { '$match' => { 'enrollees.rel_code' => 'self' } },
          { '$project' => { 'subscriber_id' => '$responsible_party_id', 'eg_id' => '$eg_id' } },
          { '$group' => { '_id' => '$subscriber_id', 'enrolled_policies' => { '$addToSet' => '$eg_id' } } }
        ]
      )
    end

    def group_by_responsible_party_query
      return inclusion_list_responsible_party_policies if inclusion_policies.present?

      Policy.collection.aggregate(
        [
          {
            '$match' => {
              updated_at: {
                '$gte' => @start_time,
                '$lte' => @end_time
              },
              responsible_party_id: {
                '$exists' => true
              }
            }
          },
          { '$unwind' => '$enrollees' },
          { '$match' => { 'enrollees.rel_code' => 'self' } },
          { '$project' => { 'subscriber_id' => '$responsible_party_id', 'eg_id' => '$eg_id' } },
          { '$group' => { '_id' => '$subscriber_id', 'enrolled_policies' => { '$addToSet' => '$eg_id' } } }
        ]
      )
    end

    def policies_by_responsible_party(&block)
      group_by_responsible_party_query.each(&block)
    end
  end
end
