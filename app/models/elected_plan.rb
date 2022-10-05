class ElectedPlan
  include Mongoid::Document
  include Mongoid::Timestamps

  include MergingModel
  embedded_in :plan_year

  field :carrier_employer_group_id, type: String
  
  field :carrier_policy_number, type: String
  field :coverage_type, type: String
  field :qhp_id, as: :hios_plan_id, type: String
  field :hbx_plan_id, type: String
  field :plan_name, type: String
  field :metal_level, type: String
  field :original_effective_date, type: Date
  field :renewal_effective_date, type: Date

  belongs_to :carrier

  scope :by_name, order_by(carrier_name: 1, plan_name: 1)

  def compare_value
    [self.carrier_id, self.qhp_id]
  end

  def plan
    Plan.find_by_hios_id_and_year(qhp_id, plan_year.start_date.year)
  end

end
