# frozen_string_literal: true

# Represents a Policy, consisting of individuals and a kind of coverage.
class Policy
  include Mongoid::Document
  include Mongoid::Timestamps
  store_in client: :edidb

  # auto_increment :_id

  field :_id, type: Integer

  field :eg_id, as: :enrollment_group_id, type: String
  field :preceding_enrollment_group_id, type: String

  field :allocated_aptc, type: BigDecimal, default: 0.00
  field :elected_aptc, type: BigDecimal, default: 0.00
  field :applied_aptc, type: BigDecimal, default: 0.00
  field :csr_amt, type: BigDecimal

  field :pre_amt_tot, as: :total_premium_amount, type: BigDecimal, default: 0.00
  field :tot_res_amt, as: :total_responsible_amount, type: BigDecimal, default: 0.00
  field :tot_emp_res_amt, as: :employer_contribution, type: BigDecimal, default: 0.00
  field :sep_reason, type: String, default: :open_enrollment
  # Carrier to bill is always set to true for individual. Only Displays on _policy_detail.html.erb for IVL
  field :carrier_to_bill, type: Boolean, default: true
  field :aasm_state, type: String
  field :updated_by, type: String
  field :is_active, type: Boolean, default: true
  field :hbx_enrollment_ids, type: Array
  field :kind, type: String

  # Adding field values Carrier specific
  field :carrier_specific_plan_id, type: String
  field :rating_area, type: String
  field :composite_rating_tier, type: String
  field :cobra_eligibility_date, type: Date
  field :term_for_np, type: Boolean, default: false

  belongs_to :carrier, counter_cache: true, index: true
  belongs_to :broker, counter_cache: true, index: true # Assumes that broker change triggers new enrollment group
  belongs_to :plan, counter_cache: true, index: true
  # belongs_to :employer, counter_cache: true, index: true
  belongs_to :responsible_party

  embeds_many :enrollees

  embeds_many :aptc_credits

  index({ :hbx_enrollment_ids => 1 })
  index({ :eg_id => 1 })
  index({ :aasm_state => 1 })
  index({ :eg_id => 1, :carrier_id => 1, :plan_id => 1 })
  index({ "enrollees.person_id" => 1 })
  index({ "enrollees.m_id" => 1 })
  index({ "enrollees.hbx_member_id" => 1 })
  index({ "enrollees.carrier_member_id" => 1 })
  index({ "enrollees.carrier_policy_id" => 1 })
  index({ "enrollees.rel_code" => 1 })
  index({ "enrollees.coverage_start" => 1 })
  index({ "enrollees.coverage_end" => 1 })

  def subscriber
    enrollees.detect { |m| m.relationship_status_code == "self" }
  end

  def coverage_type
    self.plan.coverage_type
  end

  def policy_start
    subscriber.coverage_start
  end

  def policy_end
    subscriber.coverage_end
  end

  def reported_tot_res_amt_on(date)
    return self.tot_res_amt unless multi_aptc?
    return 0.0 unless self.aptc_record_on(date)

    self.aptc_record_on(date).tot_res_amt
  end

  def reported_pre_amt_tot_on(date)
    return self.pre_amt_tot unless multi_aptc?
    return 0.0 unless self.aptc_record_on(date)

    self.aptc_record_on(date).pre_amt_tot
  end

  def reported_aptc_on(date)
    return self.applied_aptc unless multi_aptc?
    return 0.0 unless self.aptc_record_on(date)

    self.aptc_record_on(date).aptc
  end

  def multi_aptc?
    self.aptc_credits.any?
  end

  def aptc_record_on(date)
    self.aptc_credits.detect { |aptc_rec| aptc_rec.start_on <= date && aptc_rec.end_on >= date }
  end
end
