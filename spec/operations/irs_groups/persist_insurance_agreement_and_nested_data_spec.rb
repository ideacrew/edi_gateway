# frozen_string_literal: true

require 'shared_examples/cv3_family'

RSpec.describe IrsGroups::PersistInsuranceAgreementAndNestedData do
  subject { described_class.new }
  include_context 'cv3_family'

  it "should fail if policies are blank" do
    res = subject.call({ family: {}, policies: {}, irs_group: nil, primary_person: nil })
    expect(res.failure?).to be_truthy
    expect(res.failure).to eq "Policies should not be blank"
  end

  it "should fail if family is blank" do
    res = subject.call({ family: {}, policies: "test", irs_group: nil, primary_person: nil })
    expect(res.failure?).to be_truthy
    expect(res.failure).to eq "Family should not be blank"
  end

  it "should fail if irs_group is blank" do
    res = subject.call({ family: "test", policies: "test", irs_group: nil, primary_person: nil })
    expect(res.failure?).to be_truthy
    expect(res.failure).to eq "Irs group should not be blank"
  end

  it "should fail if primary_person is blank" do
    res = subject.call({ family: "test", policies: "test", irs_group: "test", primary_person: nil })
    expect(res.failure?).to be_truthy
    expect(res.failure).to eq "Primary person should not be blank"
  end

  it "should return success and store nested data under a irs group" do
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

    person = family_entity.family_members.detect(&:is_primary_applicant).person
    irs_group = InsurancePolicies::AcaIndividuals::IrsGroup.create!(irs_group_id: "2200000001000595")

    res = subject.call({ family: family_entity, policies: [policy], irs_group: irs_group, primary_person: person })
    expect(res.success?).to be_truthy
    expect(irs_group.insurance_agreements.count).to eq 1
    expect(irs_group.insurance_agreements.first.contract_holder.hbx_member_id).to eq "1000595"
    expect(irs_group.insurance_agreements.first.tax_households.count).to eq 1
    expect(irs_group.insurance_agreements.first.tax_households.first.tax_household_members.count).to eq 1
  end
end
