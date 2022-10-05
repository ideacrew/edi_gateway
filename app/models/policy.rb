class Policy
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Versioning
#  include Mongoid::Paranoia
  include AASM

  extend Mongorder
  include MoneyMath

  attr_accessor :coverage_start

  Kinds = %w(individual employer_sponsored employer_sponsored_cobra coverall unassisted_qhp insurance_assisted_qhp streamlined_medicaid emergency_medicaid hcr_chip)
  ENROLLMENT_KINDS = %w(open_enrollment special_enrollment)

  auto_increment :_id

  field :eg_id, as: :enrollment_group_id, type: String
  field :preceding_enrollment_group_id, type: String
#  field :r_id, as: :hbx_responsible_party_id, type: String

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

  # Enrollment data for federal reporting to mirror some of Enroll's
  field :kind, type: String
  field :enrollment_kind, type: String

  # flag for termination of policy due to non-payment
  field :term_for_np, type: Boolean, default: false

  validates_presence_of :eg_id
  validates_presence_of :pre_amt_tot
  validates_presence_of :tot_res_amt
  validates_presence_of :plan_id

  embeds_many :aptc_credits
  embeds_many :aptc_maximums

  embeds_many :cost_sharing_variants
  embeds_many :federal_transmissions

  embeds_many :enrollees
  accepts_nested_attributes_for :enrollees, reject_if: :all_blank, allow_destroy: true

  belongs_to :hbx_enrollment_policy, class_name: "Family", inverse_of: :hbx_enrollment_policies, index: true
  belongs_to :carrier, counter_cache: true, index: true
  belongs_to :broker, counter_cache: true, index: true # Assumes that broker change triggers new enrollment group
  belongs_to :plan, counter_cache: true, index: true
  belongs_to :employer, counter_cache: true, index: true
  belongs_to :responsible_party

  has_many :premium_payments, order: { paid_at: 1 }

  index({:hbx_enrollment_ids => 1})
  index({:eg_id => 1})
  index({:aasm_state => 1})
  index({:eg_id => 1, :carrier_id => 1, :plan_id => 1})
  index({ "enrollees.person_id" => 1 })
  index({ "enrollees.m_id" => 1 })
  index({ "enrollees.hbx_member_id" => 1 })
  index({ "enrollees.carrier_member_id" => 1})
  index({ "enrollees.carrier_policy_id" => 1})
  index({ "enrollees.rel_code" => 1})
  index({ "enrollees.coverage_start" => 1})
  index({ "enrollees.coverage_end" => 1})

  before_create :generate_enrollment_group_id, :duplicate_eg_id_check
  before_save :invalidate_find_cache
  before_save :check_for_cancel_or_term
  before_save :check_multi_aptc

  scope :all_active_states,   where(:aasm_state.in => %w[submitted resubmitted effectuated])
  scope :all_inactive_states, where(:aasm_state.in => %w[canceled carrier_canceled terminated])

  scope :individual_market, where(:employer_id => nil)
  scope :unassisted, where(:applied_aptc.in => ["0", "0.0", "0.00"])
    scope :insurance_assisted, where(:applied_aptc.nin => ["0", "0.0", "0.00"])

  # scopes of renewal reports
  scope :active_renewal_policies, where({:employer_id => nil, :enrollees => {"$elemMatch" => { :rel_code => "self", :coverage_start => {"$gt" => Date.new(2014,12,31)}, :coverage_end.in => [nil]}}})
  scope :by_member_id, ->(member_id) { where("enrollees.m_id" => {"$in" => [ member_id ]}, "enrollees.rel_code" => "self") }
  scope :with_aptc, where(PolicyQueries.with_aptc)
  scope :without_aptc, where(PolicyQueries.without_aptc)

  aasm do
    state :submitted, initial: true
    state :effectuated
    state :carrier_canceled
    state :carrier_terminated
    state :hbx_canceled
    state :hbx_terminated

    event :initial_enrollment do
      transitions from: :submitted, to: :submitted
    end

    event :effectuate do
      transitions from: :submitted, to: :effectuated
      transitions from: :effectuated, to: :effectuated
      transitions from: :hbx_canceled, to: :hbx_canceled
      transitions from: :hbx_terminated, to: :hbx_terminated
    end

    event :carrier_cancel do
      transitions from: :submitted, to: :carrier_canceled
      transitions from: :carrier_canceled, to: :carrier_canceled
      transitions from: :carrier_terminated, to: :carrier_canceled
      transitions from: :hbx_canceled, to: :hbx_canceled
      transitions from: :hbx_terminated, to: :carrier_canceled
    end

    event :carrier_terminate do
      transitions from: :submitted, to: :carrier_terminated
      transitions from: :effectuated, to: :carrier_terminated
      transitions from: :carrier_terminated, to: :carrier_terminated
      transitions from: :hbx_terminated, to: :hbx_terminated
    end

    event :hbx_cancel do
      transitions from: :submitted, to: :hbx_canceled
      transitions from: :effectuated, to: :hbx_canceled
      transitions from: :carrier_canceled, to: :hbx_canceled
      transitions from: :carrier_terminated, to: :hbx_canceled
      transitions from: :hbx_canceled, to: :hbx_canceled
      transitions from: :hbx_terminated, to: :hbx_canceled
    end

    event :hbx_terminate do
      transitions from: :submitted, to: :hbx_terminated
      transitions from: :effectuated, to: :hbx_terminated
      transitions from: :carrier_terminated, to: :carrier_terminated
      transitions from: :carrier_canceled, to: :hbx_terminated
      transitions from: :hbx_terminated, to: :hbx_terminated
    end

    event :hbx_reinstate do
      transitions from: :carrier_terminated, to: :submitted
      transitions from: :carrier_canceled, to: :submitted
      transitions from: :hbx_terminated, to: :submitted
      transitions from: :hbx_canceled, to: :submitted
    end

    # Carrier Attestation documentation reference should accompany this non-standard transition
    event :carrier_reinstate do
      transitions from: :carrier_terminated, to: :effectuated
      transitions from: :carrier_canceled, to: :effectuated
    end
  end

  def self.default_search_order
    [
      ["members.coverage_start", 1]
    ]
  end

  def canceled?
    subscriber.canceled?
  end

  def terminated?
    subscriber.terminated?
  end

  def market
    is_shop? ? 'shop' : 'individual'
  end

  def is_shop?
    !employer_id.blank?
  end

  def subscriber
    enrollees.detect { |m| m.relationship_status_code == "self" }
  end

  def is_cobra?
    cobra_eligibility_date.present? || enrollees.any? { |en| en.ben_stat == "cobra"}
  end

  def spouse
    enrollees.detect { |m| m.relationship_status_code == "spouse" && !m.canceled? }
  end

  def enrollees_sans_subscriber
    enrollees.reject { |e| e.relationship_status_code == "self" }
  end

  def dependents
    enrollees.reject { |e| e.canceled? || e.relationship_status_code == "self" ||  e.relationship_status_code == "spouse" }
  end

  def has_responsible_person?
    !self.responsible_party_id.blank?
  end

  def active_member_ids
    enrollees.reject { |e| e.canceled? || e.terminated? }.map(&:m_id)
  end

  def responsible_person
    query_proxy.responsible_person
  end

  def query_proxy
    @query_proxy ||= Queries::PolicyAssociations.new(self)
  end

  def people
    query_proxy.people
  end

  def invalidate_find_cache
    Rails.cache.delete("Policy/find/subkeys.#{enrollment_group_id}.#{carrier_id}.#{plan_id}")
    if !subscriber.nil?
      Rails.cache.delete("Policy/find/sub_plan.#{subscriber.m_id}.#{plan_id}")
    end
    true
  end

  def hios_plan_id
    self.plan.hios_plan_id
  end

  def coverage_type
    self.plan.coverage_type
  end

  def enrollee_for_member_id(m_id)
    self.enrollees.detect { |en| en.m_id == m_id }
  end

  def self.find_all_policies_for_member_id(m_id)
    self.where(
      "enrollees.m_id" => m_id
    ).order_by([:eg_id])
  end

  def check_for_cancel_or_term
    if !self.subscriber.nil?
      if self.subscriber.canceled?
        self.aasm_state = "canceled"
      elsif self.subscriber.terminated?
        self.aasm_state = "terminated"
      end
    end
    true
  end

  def multi_aptc?
    self.aptc_credits.any?
  end

  def latest_aptc_record
    latest_aptc_credit = aptc_credits.select { |aptc| aptc.start_on != aptc.end_on }.sort_by { |aptc_rec| aptc_rec.start_on }.last
    latest_aptc_credit.present? ? latest_aptc_credit : aptc_credits.sort_by { |aptc_rec| aptc_rec.start_on }.last
  end

  def aptc_record_on(date)
    self.aptc_credits.detect { |aptc_rec| aptc_rec.start_on <= date && aptc_rec.end_on >= date }
  end

  def check_multi_aptc
    return true unless self.multi_aptc?
    if self.policy_end.present?
      latest_record = self.aptc_record_on(policy_end)
    else
      latest_record = self.latest_aptc_record
    end
    if latest_record
      self.applied_aptc = latest_record.aptc
      self.pre_amt_tot = latest_record.pre_amt_tot
      self.tot_res_amt = latest_record.tot_res_amt
    end
  end

  protected
  def generate_enrollment_group_id
    self.eg_id = self.eg_id || self._id.to_s
    self.hbx_enrollment_ids = [self.eg_id]
  end

  private
  def format_money(val)
    sprintf("%.02f", val)
  end

  def filter_delimiters(str)
    str.to_s.gsub(',','') if str.present?
  end

  def filter_non_numbers(str)
    str.to_s.gsub(/\D/,'') if str.present?
  end


  def member_ids
    self.enrollees.map do |enrollee|
      enrollee.m_id
    end
  end

  def duplicate_eg_id_check
    policies = Policy.where(:eg_id => self.eg_id) || Policy.where(:hbx_enrollment_ids => self.eg_id)
    if policies.present?
      Rails.logger.error("Already Policy Exists With Exchange-Assigned ID:#{self.eg_id}, Exisiting Policy ID: #{policies.first.id}")
      raise "Already Policy Exists With Exchange-Assigned ID:#{self.eg_id}, Exisiting Policy ID: #{policies.first.id}"
    end
  end
end
