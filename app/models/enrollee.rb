# frozen_string_literal: true

# Encapsulate an Enrollee, embedded in a GlueDB policy.
class Enrollee
  include Mongoid::Document
  store_in client: :edidb

  field :m_id, as: :hbx_member_id, type: String

  field :ds, as: :disabled_status, type: Boolean, default: false
  field :ben_stat, as: :benefit_status_code, type: String, default: "active"
  field :emp_stat, as: :employment_status_code, type: String, default: "active"
  field :rel_code, as: :relationship_status_code, type: String

  field :c_id, as: :carrier_member_id, type: String
  field :cp_id, as: :carrier_policy_id, type: String
  field :pre_amt, as: :premium_amount, type: BigDecimal
  field :coverage_start, type: Date
  field :coverage_end, type: Date
  field :coverage_status, type: String, default: "active"
  field :tobacco_use, type: String
  field :termed_by_carrier, type: Boolean, default: false

  embedded_in :policy, :inverse_of => :enrollees

  def canceled?
    return false unless coverage_ended?

    (coverage_start >= coverage_end)
  end

  def terminated?
    return false unless coverage_ended?

    (coverage_start < coverage_end)
  end

  def subscriber?
    relationship_status_code == "self"
  end

  def reference_premium_for(plan, rate_date)
    plan.rate(rate_date, coverage_start, member.dob).amount
  end

  def coverage_ended?
    !coverage_end.blank?
  end
end
