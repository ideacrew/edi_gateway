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

    def group_by_subscriber_query
      Policy.collection.raw_aggregate(
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
          {
            '$project' => {
              #  "cancelled" => {
              #    "$eq" => ["$enrollees.coverage_start", "$enrollees.coverage_end"]
              #  },
              'subscriber_id' => '$enrollees.m_id',
              'eg_id' => '$eg_id'
            }
          },
          #  { "$match" => { "cancelled" => false } },
          { '$group' => { '_id' => '$subscriber_id', 'enrolled_policies' => { '$addToSet' => '$eg_id' } } }
        ]
      )
    end

    # rubocop:disable Metrics/MethodLength
    def policies_by_subscriber(&block)
      group_by_subscriber_query.each(&block)
    end

    def group_by_responsible_party_query
      Policy.collection.raw_aggregate(
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
          {
            '$project' => {
              #  "cancelled" => {
              #    "$eq" => ["$enrollees.coverage_start", "$enrollees.coverage_end"]
              #  },
              'subscriber_id' => '$responsible_party_id',
              'eg_id' => '$eg_id'
            }
          },
          # { "$match" => { "cancelled" => false } },
          { '$group' => { '_id' => '$subscriber_id', 'enrolled_policies' => { '$addToSet' => '$eg_id' } } }
        ]
      )
    end

    def policies_by_responsible_party(&block)
      group_by_responsible_party_query.each(&block)
    end
    # rubocop:enable Metrics/MethodLength
  end
end
