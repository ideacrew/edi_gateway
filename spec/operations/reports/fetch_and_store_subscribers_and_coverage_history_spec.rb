# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

RSpec.describe Reports::FetchAndStoreSubscribersAndCoverageHistory, dbclean: :before_each do
  describe 'with valid arguments' do
    let(:feature_ns) { double }
    let(:enrolled_subject_setting) { double(item: "http://localhost:3004/api/event_source/enrolled_subjects") }
    let(:coverage_history_setting) { double(item: "http://localhost:3004/api/event_source/enrolled_subjects") }
    let(:user_token) { double(item: "some token") }

    before :each do
      allow(feature_ns).to receive(:setting).with(:gluedb_enrolled_subjects_uri).and_return(enrolled_subject_setting)
      allow(feature_ns).to receive(:setting).with(:gluedb_user_access_token).and_return(user_token)
      allow(EdiGatewayRegistry).to receive(:[]).with(:gluedb_integration).and_return(feature_ns)
    end

    subject do
      described_class.new.call({
                                 year: 2022,
                                 hios_id: "12345"
                               })
    end

    context 'fetch subscriber list and store coverage information of each subscriber' do
      ActiveJob::Base.queue_adapter = :test
      before do
        stub_request(:get, "http://localhost:3004/api/event_source/enrolled_subjects?hios_id&user_token=some%20token&year=2022")
          .with(
            headers: {
              'Accept' => '*/*',
              'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
              'User-Agent' => 'Faraday v1.4.3'
            }
          )
          .to_return(status: 200, body: ["12345"].to_json, headers: {})
      end

      before do
        stub_request(:get, "http://localhost:3004/api/event_source/enrolled_subjects/12345?hios_id&user_token=some%20token&year=2022")
          .with(
            headers: {
              'Accept' => '*/*',
              'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
              'User-Agent' => 'Faraday v1.4.3'
            }
          )
          .to_return(status: 200, body: "test".to_json, headers: {})
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
