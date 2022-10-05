class Employer
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Versioning
  include Mongoid::Paranoia
  include AASM
  include MergingModel

  extend Mongorder

  field :name, type: String
  field :hbx_id, as: :hbx_organization_id, type: String
  field :fein, type: String
  field :sic_code, type: String

  # moved
  field :open_enrollment_start, type: Date
  field :open_enrollment_end, type: Date
  field :plan_year_start, type: Date
  field :plan_year_end, type: Date
  field :fte_count, type: Integer
  field :pte_count, type: Integer

  field :aasm_state, type: String
  field :msp_count, as: :medicare_secondary_payer_count, type: Integer
  field :notes, type: String
  field :dba, type: String
  field :is_active, type: Boolean, default: true

  field :name_pfx, type: String, default: ""
  field :name_first, type: String
  field :name_middle, type: String, default: ""
  field :name_last, type: String
  field :name_sfx, type: String, default: ""
  field :name_full, type: String
  field :alternate_name, type: String, default: ""

  index({ hbx_id: 1 })
  index({ fein: 1 })

  has_many :premium_payments, order: { paid_at: 1 }
  belongs_to :broker, counter_cache: true, index: true

  has_many :plan_years
  embeds_many :elected_plans

  # has_and_belongs_to_many :employees, class_name: 'Person', inverse_of: :employers, order: {name_last: 1, name_first: 1}
  has_many :employees, class_name: 'Person', inverse_of: :employer, order: {name_last: 1, name_first: 1}
  has_and_belongs_to_many :carriers, order: { name: 1 }, inverse_of: nil
  has_and_belongs_to_many :plans, order: { name: 1, hios_plan_id: 1 }

  index({"elected_plans.carrier_employer_group_id" => 1})
  index({"elected_plans.hbx_plan_id" => 1})
  index({"elected_plans.qhp_id" => 1})
  accepts_nested_attributes_for :elected_plans, reject_if: :all_blank, allow_destroy: true


  embeds_many :employer_contacts, :inverse_of => :employer
  accepts_nested_attributes_for :employer_contacts, reject_if: :all_blank, allow_destroy: true


  embeds_many :employer_office_locations, :inverse_of => :employer
  accepts_nested_attributes_for :employer_office_locations, reject_if: :all_blank, allow_destroy: true

  embeds_many :addresses, :inverse_of => :employer
  accepts_nested_attributes_for :addresses, reject_if: :all_blank, allow_destroy: true

  embeds_many :phones, :inverse_of => :employer
  accepts_nested_attributes_for :phones, reject_if: :all_blank, allow_destroy: true

  embeds_many :emails, :inverse_of => :employer
  accepts_nested_attributes_for :emails, reject_if: :all_blank, allow_destroy: true

  validates_length_of :fein, allow_blank: true, allow_nil: true, minimum: 9, maximum: 9

  before_save :initialize_name_full
  before_save :invalidate_find_caches

  scope :by_name, order_by(name: 1)
  scope :by_hbx_id, lambda { |employer_hbx_id| where(:hbx_id => employer_hbx_id) }

  def payment_transactions
    PremiumPayment.payment_transactions_for(self)
  end


  aasm do
    state :registered, initial: true
    state :enrollment_open
    state :enrollment_closed
    state :terminated

    event :start_enrollment do
      transitions from: [:registered, :enrollment_closed], to: :enrollment_open
    end

    event :end_enrollment do
      transitions from: :enrollment_open, to: :enrollment_closed
    end
  end

  def fein=(val)
    return if val.blank?
    write_attribute(:fein, val.to_s.gsub(/[^0-9]/i, ''))
  end

  def invalidate_find_caches
    Rails.cache.delete("Employer/find/fein.#{fein}")
    true
  end

  def todays_bill
    e_id = self._id
    value = Policy.collection.aggregate(
      { "$match" => {
        "employer_id" => e_id,
        "enrollment_members" =>
        {
          "$elemMatch" => {"$or" => [{
            "coverage_end" => nil
          },
          {"coverage_end" => { "$gt" => Time.now }}
          ]}

        }
      }},
      {"$group" => {
        "_id" => "$employer_id",
        "total" => { "$addToSet" => "$pre_amt_tot" }
      }}
    ).first["total"].inject(0.00) { |acc, item|
      acc + BigDecimal.new(item)
    }
    "%.2f" % value
  end

  def self.default_search_order
    [[:name, 1]]
  end

  def self.search_hash(s_rex)
    search_rex = Regexp.compile(Regexp.escape(s_rex), true)
    {
      "$or" => ([
        {"name" => search_rex},
        {"fein" => search_rex},
        {"hbx_id" => search_rex}
      ])
    }
  end

  def self.find_for_fein(e_fein)
#    Rails.cache.fetch("Employer/find/fein.#{e_fein}") do
      Employer.where(:fein => e_fein).first
#    end
  end

  def self.find_for_carrier_and_group_id(carrier_id, group_id)
      py = PlanYear.where({ :elected_plans => {
        "$elemMatch" => {
          "carrier_id" => carrier_id,
          "carrier_employer_group_id" => group_id
        }
      }
      }).first
      Maybe.new(py).employer.value
  end

  def plan_year_of(coverage_start_date)
    # The #to_a is a caching thing.
    plan_years.to_a.detect do |py|
      (py.start_date <= coverage_start_date) && (py.end_date >= coverage_start_date)
    end
  end

  def renewal_plan_year_of(coverage_start_date)
    plan_year_of(coverage_start_date + 1.year)
  end

  def full_name
    [name_pfx, name_first, name_middle, name_last, name_sfx].reject(&:blank?).join(' ').downcase.gsub(/\b\w/) {|first| first.upcase }
  end

  def initialize_name_full
    self.name_full = full_name
  end

end