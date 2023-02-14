# frozen_string_literal: true

require 'shared_examples/cv3_family'

RSpec.describe IrsGroups::SeedIrsGroup do
  subject { described_class.new }
  include_context 'cv3_family'

  it "should fail if payload is invalid" do
    res = subject.call({ payload: {} })
    expect(res.failure).to be_truthy
  end

  it "should fail if it is unable to fetch person from gluedb" do
    res = subject.call({ payload: family_params.to_h })
    expect(res.failure?).to be_truthy
    expect(res.failure).to match(/Unable to find IRS group for family/)
  end

  it "should seed IRS group and return success if everything is valid" do
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
                            coverage_start: Date.new(Date.today.year, 1, 1), cp_id: "12345")
    policy = Policy.create!(enrollment_group_id: "1000", plan: plan,
                            kind: 'individual',
                            aasm_state: "submitted",
                            hbx_enrollment_ids: ["1000"],
                            broker_id: broker.id,
                            responsible_party: person.responsible_parties.first,
                            carrier_id: carrier.id,
                            enrollees: [enrollee])
    contract_holder = People::Person.create!(hbx_id: person.authority_member_id)

    insurance_provider = InsurancePolicies::InsuranceProvider.create!(hios_id: "33653", title: "test")
    insurance_product = InsurancePolicies::InsuranceProduct.create!(hios_plan_id: "33635ME12344",
                                                                    plan_year: policy.plan.year,
                                                                    insurance_provider: insurance_provider)

    insurance_agreement = InsurancePolicies::InsuranceAgreement.create!(insurance_provider: insurance_provider,
                                                                        contract_holder: contract_holder)
    irs_group = InsurancePolicies::AcaIndividuals::IrsGroup.create!(irs_group_id: "2200000001234567")

    _insurance_policy = InsurancePolicies::AcaIndividuals::InsurancePolicy.create!(policy_id: "1000",
                                                                                   insurance_product: insurance_product,
                                                                                   insurance_agreement: insurance_agreement,
                                                                                   irs_group: irs_group)

    res = subject.call({ payload: family_params.to_h })
    expect(res.success?).to be_truthy
    expect(InsurancePolicies::AcaIndividuals::IrsGroup.all.count).to eq(1)
    expect(InsurancePolicies::AcaIndividuals::TaxHousehold.all.count).to eq(1)
    expect(InsurancePolicies::AcaIndividuals::Enrollment.all.count).to eq(1)
  end
end
