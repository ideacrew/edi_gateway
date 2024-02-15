# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Reports::FetchAndStoreSubscribersAndCoverageHistory, dbclean: :before_each do
  describe 'with valid arguments' do
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

    let!(:policy_1) do
      policy = FactoryBot.create(:policy, id: '012345', plan_id: plan.id, coverage_start: coverage_start,
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

    subject do
      described_class.new.call({
                                 year: 2022,
                                 carrier_hios_id: "12345"
                               })
    end

    context 'fetch subscriber list and store coverage information of each subscriber' do
      ActiveJob::Base.queue_adapter = :test

      before do
        allow(SubscriberInventory).to receive(:subscriber_ids_for).with("12345", 2022).and_return([policy_1.subscriber.m_id])
      end

      it 'should return success and create audit datum' do
        expect(subject.success?).to be_truthy
        expect(AuditReportDatum.all.count).to eq(1)
        expect do
          RequestSubscriberCoverageHistoryJob.perform_later(AuditReportDatum.all.first.id.to_s)
        end.to have_enqueued_job
      end
    end
  end
end
