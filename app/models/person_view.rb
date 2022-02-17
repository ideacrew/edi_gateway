class PersonView
  attr_reader :hbx_id, :policies, :rp_policies

  def self.find(hbx_id)
    self.new(hbx_id)
  end

  def initialize(p_id)
    @hbx_id = p_id
    @policies = []
    @rp_policies = []
    find_policies
    find_rp_policies
  end

  def find_policies
    @policies = ::Policies::PolicyRecord.includes({
      :coverage_span_records => :coverage_span_enrollee_records
    }).left_outer_joins({
      :coverage_span_records => :coverage_span_enrollee_records
    }).where({::Policies::CoverageSpanRecord.table_name => {::Policies::CoverageSpanEnrolleeRecord.table_name => {hbx_member_id: @hbx_id}}})
  end

  def find_rp_policies
    @rp_policies = ::Policies::PolicyRecord.where(responsible_party_hbx_id: @hbx_id).includes([:coverage_span_records])
  end

end