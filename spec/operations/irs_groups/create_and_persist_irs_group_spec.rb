# frozen_string_literal: true

require 'shared_examples/cv3_family'

RSpec.describe IrsGroups::CreateAndPersistIrsGroup do
  subject { described_class.new }
  include_context 'cv3_family'

  it "should fail if payload is invalid" do
    res = subject.call({ family: {}, policies: {} })
    expect(res.failure).to be_truthy
  end

  it "should fail if passed in family is not a family entity" do
    res = subject.call({ family: {}, policies: {} })
    expect(res.failure).to be_truthy
    expect(res.failure).to eq "Please pass in family entity"
  end

  it "should fail if policies are blank" do
    res = subject.call({ family: family_entity, policies: {} })
    expect(res.failure).to be_truthy
    expect(res.failure).to eq "Policies are blank"
  end

  it "should return success and create new irs group" do
    lookup_id = "1000595"
    person = Person.create(name_pfx: 'Mr', name_first: 'John')
    resp_party = ResponsibleParty.new(_id: 1, entity_identifier: "parent")
    member = Member.new(hbx_member_id: lookup_id)
    person.members = [member]
    person.responsible_parties = [resp_party]
    person.save!
    person.update(authority_member_id: person.members.first.hbx_member_id)
    carrier = Carrier.create!(name: "test_carrier")
    carrier_profile = CarrierProfile.new(id: 1, fein: "12345")
    carrier.carrier_profiles << carrier_profile
    broker = Broker.create!
    plan = Plan.create!(:name => "test_plan", :hios_plan_id => "966667ME-01", carrier_id: carrier.id, :coverage_type => "health",
                        year: Date.today.year)
    enrollee = Enrollee.new(m_id: person.authority_member.hbx_member_id, rel_code: 'self',
                            coverage_start: Date.new(Date.today.year, 1, 1))
    policy = Policy.create!(id: 1, enrollment_group_id: "12345", plan: plan,
                            kind: 'individual',
                            aasm_state: "submitted",
                            broker_id: broker.id,
                            responsible_party: person.responsible_parties.first,
                            carrier_id: carrier.id,
                            enrollees: [enrollee])

    res = subject.call({ family: family_entity, policies: [policy] })
    expect(res.success?).to be_truthy
    expect(InsurancePolicies::AcaIndividuals::IrsGroup.all.count).to eq 1
    expect(InsurancePolicies::AcaIndividuals::IrsGroup.all.first.family_assigned_hbx_id).to eq family_entity.hbx_id
  end
end
