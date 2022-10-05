class Plan
  include Mongoid::Document
  include Mongoid::Timestamps

  extend Mongorder

  field :name, type: String
  field :abbrev, as: :abbreviation, type: String
  field :hbx_plan_id, type: String  # internal ID for plan
  field :hios_plan_id, type: String
  field :coverage_type, type: String
  field :metal_level, type: String
  field :market_type, type: String
  field :ehb, as: :ehb_max_as_percent, type: BigDecimal, default: 0.0
  field :year, type: Integer

  index({ name: 1 })
  index({ carrier_id: 1 })
  index({ hbx_plan_id: 1 }, { name: "exchange_plan_id_index" })
	index({ hios_plan_id: 1 }, { unique: false, name: "hios_plan_id_index" })
  index({ coverage_type: 1 })
  index({ metal_level: 1 })
  index({ market_type: 1 })
  index({ "premium_tables.age" => 1 })
  index({ "premium_tables.rate_start_date" => 1 })
  index({ "premium_tables.rate_end_date" => 1 })

  validates_inclusion_of :coverage_type, in: ["health", "dental"]
#  validates_inclusion_of :market_type, in: ["individual", "shop"]

	belongs_to :carrier, index: true
  belongs_to :renewal_plan, :class_name => "Plan"
  has_many :policies, :inverse_of => :plan
  has_and_belongs_to_many :employers
  embeds_many :premium_tables

  before_save :invalidate_find_cache

  scope :by_name, order_by(name: 1, hios_plan_id: 1)

  def invalidate_find_cache
#    Rails.cache.delete("Plan/find/hios_plan_id.#{self.hios_plan_id}")
    Rails.cache.delete("Plan/find/hios_plan_id.#{self.hios_plan_id}.#{self.year}")
    true
  end

  def self.find_by_hios_id_and_year(h_id, year)
#    Rails.cache.fetch("Plan/find/hios_plan_id.#{h_id}.#{year}") do
      Plan.where(
        :hios_plan_id => h_id,
        :year => year
      ).first
#    end
  end

  # Provide premium rate given the rate schedule, date coverage will start, and family_member age when coverage starts
  def rate(rate_period_date, benefit_begin_date, birth_date)
    age = Ager.new(birth_date).age_as_of(benefit_begin_date)
    premiums = Collections::Premiums.new(self.premium_tables).for_date(rate_period_date).for_age(age)
    premiums.to_a.first
  end

  def premium_for_enrollee(enrollee)
    rate(enrollee.rate_period_date, enrollee.benefit_begin_date, enrollee.birth_date)
  end

  def self.default_search_order
    [
      ["name", 1]
    ]
  end

  def self.search_hash(s_str)
    search_rex = Regexp.compile(Regexp.escape(s_str), true)
    {
      "$or" => [
        {"name" => search_rex}
      ]
    }
  end
end
