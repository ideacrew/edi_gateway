# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
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

  def canceled?
    subscriber.canceled?
  end

  def policy_end_on
    subscriber.coverage_end.present? ? subscriber.coverage_end : subscriber.coverage_start.end_of_year
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

  def reported_aptc_month(month)
    if aptc_credits.count.zero?
      applied_aptc
    else
      credits = aptc_credits.select { |aptc_rec| (aptc_rec.start_on.month..aptc_rec.end_on.month).include?(month) }
      credits.count.positive? ? credits.sum(&:aptc).to_f.round(2) : 0.0
    end
  end

  def reported_pre_amt_tot_month(month)
    if aptc_credits.count.zero?
      pre_amt_tot
    else
      credits = aptc_credits.select { |aptc_rec| (aptc_rec.start_on.month..aptc_rec.end_on.month).include?(month) }
      credits.count.positive? ? credits.sum(&:pre_amt_tot).to_f.round(2) : 0.0
    end
  end

  def covered_enrollees_as_of(month, year)
    month_begin = Date.new(year, month, 1)
    month_end = month_begin.end_of_month

    enrollees.select do |enrollee|
      enrollee_coverage_end = enrollee.coverage_end.present? ? enrollee.coverage_end : enrollee.coverage_start.end_of_year
      (enrollee.coverage_start <= month_end) && (enrollee_coverage_end >= month_begin)
    end
  end

  def self.policies_for_month(month, calendar_year, policies)
    pols = []
    policies.each do |pol|
      pols << policy_reported_month(month, calendar_year, pol)
    end
    pols.uniq.compact
  end

  def self.policy_reported_month(month, calendar_year, pol)
    end_of_month = Date.new(calendar_year, month, 1).end_of_month
    return unless pol.subscriber.coverage_start < end_of_month

    start_date = pol.policy_start
    end_date = pol.policy_end_on
    coverage_end_month = end_date.month
    coverage_end_month = 12 if calendar_year != end_date.year
    (start_date.month..coverage_end_month).include?(month) ? pol : nil
  end

  def fetch_npt_h36_prems(tax_household, calendar_month)
    hbx_ids = enrollees.map(&:m_id)
    th_mems = tax_household.tax_household_members.where(:person_hbx_id.in => hbx_ids)
    slcsp, pre_amt_tot_month = slcsp_pre_amt_tot_values(calendar_month, th_mems)
    aptc = check_for_npt_prem(calendar_month)
    [format('%.2f', slcsp), format('%.2f', aptc), format('%.2f', pre_amt_tot_month)]
  end

  def slcsp_pre_amt_tot_values(calendar_month, th_mems)
    if term_for_np && policy_end_on.month == calendar_month
      [0.0, 0.0]
    else
      slcsp = th_mems.map { |mem| mem.slcsp_benchmark_premium.to_f }.sum
      pre_amt_tot_month = reported_pre_amt_tot_month(calendar_month)
      pre_amt_tot_month = (pre_amt_tot_month * plan.ehb).to_f.round(2)
      [slcsp, pre_amt_tot_month]
    end
  end

  def check_for_npt_prem(calendar_month)
    aptc_credit = reported_aptc_month(calendar_month)
    if term_for_np
      aptc_credit
    else
      aptc_credit > pre_amt_tot.to_f.round(2) ? pre_amt_tot.to_f.round(2) : aptc_credit
    end
  end
end

# rubocop:enable Metrics/ClassLength
