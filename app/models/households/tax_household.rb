# frozen_string_literal: true

module Households
  # tax households
  class TaxHousehold
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :tax_household_group, class_name: "Households::TaxHouseholdGroup"

    field :hbx_id, type: String
    field :allocated_aptc, type: Money
    field :max_aptc, type: Money
    field :start_date, type: Date
    field :end_date, type: Date
    field :is_immediate_family, type: Boolean

    embeds_many :tax_household_members, class_name: "Households::TaxHouseholdMember",
                cascade_callbacks: true
    accepts_nested_attributes_for :tax_household_members, allow_destroy: true


    def primary
      primary_thh = tax_household_members.where(relation_with_primary: "self").first
      if is_immediate_family == true
        primary_thh
      else
        tax_household_members.where(tax_filer_status: "tax_filer").first || primary_thh
      end
    end

    def spouse
      tax_household_members.where(relation_with_primary: 'spouse').first
    end

    def dependents
      tax_household_members.select do |member|
        member.id.to_s != primary.id.to_s && !%w(spouse self).include?(member.relation_with_primary)
      end
    end
  end
end