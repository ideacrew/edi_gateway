# frozen_string_literal: true

RSpec.describe Generators::CoverageInformationSerializer, type: :model, :dbclean => :after_each do
  let(:plan)           { FactoryBot.create(:plan, ehb: "0.997144") }
  let(:calender_year)  { Date.today.year }
  let(:coverage_start) { Date.new(calender_year, 1, 1) }
  let(:coverage_end)   { Date.new(calender_year, 12, 31) }

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

  context 'should build coverage information hash for primary as a subscriber policies with an enrollee',
          :dbclean => :after_each do
    let!(:policy_1) do
      policy = FactoryBot.create(:policy, id: '999999', plan_id: plan.id, coverage_start: coverage_start,
                                          coverage_end: coverage_end)
      policy.enrollees[0].m_id = primary.authority_member.hbx_member_id
      policy.enrollees[0].coverage_end = nil
      policy.enrollees[1].m_id = child.authority_member.hbx_member_id
      policy.enrollees[1].rel_code = 'child'
      policy.enrollees[1].coverage_start = Date.new(calender_year, 1, 1)
      policy.enrollees[1].coverage_end = Date.new(calender_year, 5, 31)
      policy.save
      policy
    end

    it 'should create 2 segments' do
      subject = Generators::CoverageInformationSerializer.new(primary, [plan.id])
      result = subject.process
      expect(result[0][:policy_id]).to eq policy_1._id.to_s
      expect(result[0][:coverage_start]).to eq coverage_start.strftime('%Y-%m-%d')
      expect(result[0][:coverage_end]).to eq coverage_end.strftime('%Y-%m-%d')
      expect(result[0][:coverage_kind]).to eq 'individual'
      expect(result[0][:last_maintenance_time]).to eq policy_1.updated_at.strftime("%H%M%S%L")
      expect(result[0][:enrollees].count).to eq 2
      expect(result[0][:enrollees][0][:segments].count).to eq 2
      expect(result[0][:enrollees][1][:segments].count).to eq 1
      expect(result[0][:enrollees][0][:addresses]).to be_present
    end

    it 'should include canceled enrollee premium into total_premium_amount' do
      subject = Generators::CoverageInformationSerializer.new(primary, [plan.id])
      result = subject.process
      expect(result[0][:enrollees][0][:segments][0][:aptc_amount]).to eq 3.33
      expect(result[0][:enrollees][0][:segments][0][:total_premium_amount]).to eq 1333.32
      expect(result[0][:enrollees][0][:segments][1][:total_premium_amount]).to eq 666.66
      expect(result[0][:enrollees][1][:segments][0][:individual_premium_amount]).to eq 666.66
    end
  end

  context 'should build coverage information hash for primary as a subscriber policies with a canceled enrollee',
          :dbclean => :after_each do
    let!(:policy_1) do
      policy = FactoryBot.create(:policy, id: '999999', plan_id: plan.id, coverage_start: coverage_start,
                                          coverage_end: coverage_end)
      policy.enrollees[0].m_id = primary.authority_member.hbx_member_id
      policy.enrollees[0].coverage_end = nil
      policy.enrollees[1].m_id = child.authority_member.hbx_member_id
      policy.enrollees[1].rel_code = 'child'
      policy.enrollees[1].coverage_start = Date.new(calender_year, 1, 1)
      policy.enrollees[1].coverage_end = Date.new(calender_year, 1, 1)
      policy.save
      policy
    end

    it 'should create 1 segment' do
      subject = Generators::CoverageInformationSerializer.new(primary, [plan.id])
      result = subject.process
      expect(result[0][:policy_id]).to eq policy_1._id.to_s
      expect(result[0][:coverage_start]).to eq coverage_start.strftime('%Y-%m-%d')
      expect(result[0][:coverage_end]).to eq coverage_end.strftime('%Y-%m-%d')
      expect(result[0][:coverage_kind]).to eq 'individual'
      expect(result[0][:last_maintenance_time]).to eq policy_1.updated_at.strftime("%H%M%S%L")
      expect(result[0][:enrollees].count).to eq 2
      expect(result[0][:enrollees][0][:segments].count).to eq 1
      expect(result[0][:enrollees][0][:segments][1]).to eq nil
      expect(result[0][:enrollees][1][:segments].count).to eq 1
      expect(result[0][:enrollees][0][:addresses]).to be_present
    end

    it 'should not include canceled enrollee premium into total_premium_amount' do
      subject = Generators::CoverageInformationSerializer.new(primary, [plan.id])
      result = subject.process
      expect(result[0][:enrollees][0][:segments][0][:total_premium_amount]).to eq 666.66
      expect(result[0][:enrollees][0][:segments][0][:individual_premium_amount]).to eq 666.66
      expect(result[0][:enrollees][1][:segments][0][:individual_premium_amount]).to eq 666.66
    end
  end

  context "when the policy is canceled and no aptc credits present" do
    let!(:canceled_policy) do
      policy = FactoryBot.create(:policy, id: '999999', plan_id: plan.id, coverage_start: Date.new(calender_year, 1, 1),
                                          coverage_end: Date.new(calender_year, 1, 1), aasm_state: "canceled")
      policy.enrollees[0].m_id = primary.authority_member.hbx_member_id
      policy.enrollees[0].coverage_end = nil
      policy.enrollees[1].m_id = child.authority_member.hbx_member_id
      policy.enrollees[1].rel_code = 'child'
      policy.enrollees[1].coverage_start = Date.new(calender_year, 1, 1)
      policy.enrollees[1].coverage_end = Date.new(calender_year, 1, 1)
      policy.save
      policy
    end

    it 'should pull aptc amount and premium amounts from the policy' do
      subject = Generators::CoverageInformationSerializer.new(primary, [plan.id])
      result = subject.process
      expect(result[0][:enrollees][0][:segments][0][:total_premium_amount]).to eq canceled_policy.pre_amt_tot.to_f
      expect(result[0][:enrollees][0][:segments][0][:aptc_amount]).to eq canceled_policy.applied_aptc.to_f
    end
  end

  context "when the policy is canceled and aptc credits present" do
    let!(:canceled_policy) do
      policy = FactoryBot.create(:policy, id: '999999', plan_id: plan.id, coverage_start: Date.new(calender_year, 1, 1),
                                          coverage_end: Date.new(calender_year, 1, 1), aasm_state: "canceled")
      policy.enrollees[0].m_id = primary.authority_member.hbx_member_id
      policy.enrollees[0].coverage_end = nil
      policy.enrollees[1].m_id = child.authority_member.hbx_member_id
      policy.enrollees[1].rel_code = 'child'
      policy.enrollees[1].coverage_start = Date.new(calender_year, 1, 1)
      policy.enrollees[1].coverage_end = Date.new(calender_year, 1, 1)
      policy.save
      policy
    end

    let(:aptc_credit) do
      AptcCredit.new(start_on: Date.new(calender_year, 1, 1),
                     end_on: Date.new(calender_year, 1, 1),
                     pre_amt_tot: 550.00,
                     aptc: 100.00,
                     tot_res_amt: 450.00)
    end

    it 'should pull aptc amount and premium amounts from the policy' do
      canceled_policy.aptc_credits << aptc_credit
      subject = Generators::CoverageInformationSerializer.new(primary, [plan.id])
      result = subject.process
      expect(result[0][:enrollees][0][:segments][0][:total_premium_amount]).to eq aptc_credit.pre_amt_tot.to_f
      expect(result[0][:enrollees][0][:segments][0][:aptc_amount]).to eq aptc_credit.aptc.to_f
    end
  end
end
