# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

RSpec.describe Reports::RcnoReportGenerationProcessor do
  include Dry::Monads[:result, :do]

  describe 'Failure' do
    context 'No params' do
      it 'should fail' do
        subject = described_class.new.call({})
        expect(subject.failure?).to eq true
        expect(subject.failure).to eq 'Pass in HIOS Id of the carrier'
      end
    end

    context 'No file exists' do
      it 'should fail' do
        subject = described_class.new.call({ hios_id: "33653", year: 2022 })
        expect(subject.failure?).to eq true
        expect(subject.failure).to eq 'Unable to find RCNI file for carrier hios_id 33653, please upload one'
      end
    end
  end

  describe 'success' do
    let(:feature_ns) { double }
    let(:enrolled_subject_setting) { double(item: "http://localhost:3004/api/event_source/enrolled_subjects") }
    let(:coverage_history_setting) { double(item: "http://localhost:3004/api/event_source/enrolled_subjects") }
    let(:user_token) { double(item: "some token") }

    before :each do
      allow(feature_ns).to receive(:setting).with(:gluedb_enrolled_subjects_uri).and_return(enrolled_subject_setting)
      allow(feature_ns).to receive(:setting).with(:gluedb_user_access_token).and_return(user_token)
      allow(EdiGatewayRegistry).to receive(:[]).with(:gluedb_integration).and_return(feature_ns)
      stub_request(:get, "http://localhost:3004/api/event_source/enrolled_subjects/1234567?hios_id=33653&user_token=some%20token&year=2022")
        .with(
          headers: {
            'Accept' => '*/*',
            'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'User-Agent' => 'Faraday v1.4.3'
          }
        )
        .to_return(status: 200, body: [{ enrollment_group_id: "12345" }].to_json, headers: {})
    end

    it 'should be success' do
      subject = described_class.new
      File.stub(:exist?).and_return(true)
      allow(subject).to receive(:fetch_rcni_file_path).and_return(Success("#{Rails.root}/spec/test_data/RCNI_33653.txt"))
      subject.call({ hios_id: "33653", year: 2022 })

      expect(AuditReportDatum.all.count).to eq 1
    end
  end
end
