# frozen_string_literal: true

# Collection of subscribers information
class SubscriberInventory
  def self.subscriber_ids_for(carrier_hios, year)
    plans = plans_for(carrier_hios, year)
    aggregate_query_for_subscribers_under_plans(plans)
  end

  def self.aggregate_query_for_subscribers_under_plans(plans)
    pipeline = [
      { "$match" => { "plan_id" => { "$in" => plans.map(&:_id) } } },
      { "$unwind" => "$enrollees" },
      { "$match" => { "enrollees.rel_code" => "self" } },
      { "$group" => { "_id" => "$enrollees.m_id" } }
    ]
    result = Policy.collection.aggregate(pipeline)
    result.map { |rec| rec["_id"] }
  end

  def self.plans_for(carrier_hios, year)
    hios_regexp = /^#{carrier_hios}/
    Plan.where({
                 year: year,
                 hios_plan_id: hios_regexp
               })
  end

  def self.coverage_inventory_for(person, filters = {})
    plan_ids = select_filtered_plan_ids(filters)
    Generators::CoverageInformationSerializer.new(person, plan_ids).process
  end

  def self.select_filtered_plan_ids(filters = {})
    filter_criteria = Hash.new
    if filters.key?(:hios_id)
      hios_regexp = /^#{filters[:hios_id]}/
      filter_criteria[:hios_plan_id] = hios_regexp
    end
    filter_criteria[:year] = filters[:year] if filters.key?(:year)
    return nil if filter_criteria.empty?

    Rails.cache.fetch("plan-ids-#{filter_criteria[:hios_plan_id]}-#{filter_criteria[:year]}", expires_in: 24.hour) do
      plans = Plan.where(filter_criteria)
      plans.pluck(:_id)
    end
  end
end
