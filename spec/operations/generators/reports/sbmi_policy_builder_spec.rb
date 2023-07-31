# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Generators::Reports::SbmiPolicyBuilder do
  after(:each) do
    DatabaseCleaner.clean
    FileUtils.rm_rf(Dir["#{Rails.root}/sbmi"])
  end

  let(:plan) { FactoryBot.create(:plan) }

  let(:primary) do
    person = FactoryBot.create :person, dob: Date.new(1970, 5, 1), name_first: "John", name_last: "Roberts"
    person.update(authority_member_id: person.members.first.hbx_member_id)
    person
  end

  let!(:child) do
    person = FactoryBot.create :person, dob: Date.new(1998, 9, 6), name_first: "Adam", name_last: "Roberts"
    person.update(authority_member_id: person.members.first.hbx_member_id)
    person
  end

  let(:policy) do
    policy = FactoryBot.create :policy, plan_id: plan.id, rating_area: "ME0"
    policy.enrollees[0].m_id = primary.authority_member.hbx_member_id
    policy.enrollees[1].m_id = child.authority_member.hbx_member_id
    policy.enrollees[1].rel_code = 'child'
    policy.save
    policy
  end

  it 'should build sbmi policy struct and return success' do
    result = Generators::Reports::SbmiPolicyBuilder.new.call({ policy: policy })
    expect(result.success?).to be_truthy
    sbmi_policy = result.value!
    expect(sbmi_policy.coverage_start).to eq policy.policy_start
    expect(sbmi_policy.coverage_end).to eq policy.policy_end_on
    expect(sbmi_policy.coverage_household.size).to eq 2
    expect(sbmi_policy.financial_loops).to be_present
  end
end
