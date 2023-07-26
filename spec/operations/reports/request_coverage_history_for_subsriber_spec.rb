# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Reports::RequestCoverageHistoryForSubscriber, dbclean: :before_each do
  describe 'with valid arguments' do
    let(:plan)           { create(:plan, ehb: "0.997144") }
    let(:calender_year)  { Date.today.year }
    let(:coverage_start) { Date.new(calender_year, 1, 1) }
    let(:coverage_end)   { Date.new(calender_year, 12, 31) }

    let(:primary) do
      person = create :person, dob: Date.new(1970, 5, 1), name_first: "John", name_last: "Roberts"
      person.update(authority_member_id: person.members.first.hbx_member_id)
      person
    end

    let!(:child) do
      person = create(:person, dob: Date.new(1998, 9, 6), name_first: "Adam", name_last: "Roberts")
      person.update(authority_member_id: person.members.first.hbx_member_id)
      person
    end

    let!(:policy_1) do
      policy = create(:policy, id: '123456', plan_id: plan.id, coverage_start: coverage_start, coverage_end: coverage_end)
      policy.enrollees[0].m_id = primary.authority_member.hbx_member_id
      policy.enrollees[0].coverage_end = nil
      policy.enrollees[1].m_id = child.authority_member.hbx_member_id
      policy.enrollees[1].rel_code = 'child'
      policy.enrollees[1].coverage_start = Date.new(calender_year, 1, 1)
      policy.enrollees[1].coverage_end = Date.new(calender_year, 5, 31)
      policy.save
      policy
    end

    let(:audit_report_datum) do
      create(:audit_report_datum, hios_id: "12345", year: 2022, subscriber_id: policy_1.subscriber.m_id)
    end
    let(:payload_response) do
      [{ "enrollment_group_id" => "1213539",
         "enrollees" =>
                                [{ "hbx_member_id" => "1014042",
                                   "segments" =>
                                  [{ "id" => "1014042-35331-20220101", "effective_start_date" => "2022-01-01" }] }] }]
    end

    subject do
      described_class.new.call({
                                 audit_report_datum: audit_report_datum
                               })
    end

    context 'fetch coverage history for subscriber and update audit report datum' do
      before do
        allow(SubscriberInventory).to receive(:coverage_inventory_for).with(any_args).and_return(payload_response)
      end

      it 'returns success' do
        expect(subject.success?).to be_truthy
        expect(audit_report_datum.payload).to eq payload_response.to_json
      end
    end
  end
end
