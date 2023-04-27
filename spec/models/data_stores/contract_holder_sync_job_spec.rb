# frozen_string_literal: true

RSpec.describe DataStores::ContractHolderSyncJob, type: :model, db_clean: :before do
  after(:each) do
    DatabaseCleaner.clean
  end

  describe 'validate_timespan' do
    let!(:previous_jobs) do
      create(:contract_holder_sync,
             time_span_start: (Date.today - 3.days).beginning_of_day,
             time_span_end: (Date.today - 3.days).end_of_day)

      create(:contract_holder_sync,
             time_span_start: (Date.today - 2.days).beginning_of_day,
             time_span_end: (Date.today - 2.days).end_of_day)
    end

    let(:time_span_start) { (Date.today - 1.days).beginning_of_day }
    let(:time_span_end) { (Date.today - 1.days).end_of_day }

    let(:params) do
      {
        time_span_start: time_span_start,
        time_span_end: time_span_end
      }
    end

    subject { described_class.new(params) }

    before do
      subject.save
    end

    context 'Time range is empty' do
      let(:time_span_start) { nil }
      let(:time_span_end) { nil }

      it 'should reset timespans using latest job timespan' do
        expect(described_class.last.time_span_start).to eq described_class.all[-2].time_span_end
        expect(described_class.last.time_span_end).to be_present
      end
    end

    context 'Time range start_at == most recent refresh job end_at & precedes end_at' do
      let(:time_span_start) { described_class.last.time_span_end }

      it 'should not change dates' do
        expect(described_class.last.time_span_start).to eq described_class.all[-2].time_span_end
        expect(described_class.last.time_span_end.utc.to_s).to eq time_span_end.to_s
      end
    end

    context 'Time range start_at value is in the future' do
      let(:time_span_start) { (Date.today + 1.days).beginning_of_day }

      it 'should reset dates to current' do
        expect(described_class.last.time_span_start).to eq described_class.all[-2].time_span_end
        expect(described_class.last.time_span_end.utc.to_s).to eq time_span_end.to_s
      end
    end

    context 'Time range end_at value is in the future' do
      let(:time_span_end) { (Date.today + 1.days).end_of_day }

      it 'should reset dates to current' do
        expect(described_class.last.time_span_start).to eq described_class.all[-2].time_span_end
        expect(described_class.last.time_span_end).not_to eq time_span_end
      end
    end

    context 'Time range start_at value is earlier than the most recent refresh' do
      let(:time_span_start) { (Date.today - 3.days).beginning_of_day }

      it 'should reset dates to current' do
        expect(described_class.last.time_span_start).to eq described_class.all[-2].time_span_end
        expect(described_class.last.time_span_end.utc.to_s).to eq time_span_end.to_s
      end
    end

    context 'Time range end_at value is earlier than the most recent refresh' do
      let(:time_span_end) { (Date.today - 3.days).end_of_day }

      it 'should reset dates to current' do
        expect(described_class.last.time_span_start).to eq described_class.all[-2].time_span_end
        expect(described_class.last.time_span_end).not_to eq time_span_end
      end
    end

    context 'Time range end_at value precedes Time Range start_at value' do
      let(:time_span_start) { Date.today.beginning_of_day }
      let(:time_span_end) { (Date.today - 2.days).end_of_day }

      it 'should reset dates to current' do
        expect(described_class.last.time_span_start).to eq described_class.all[-2].time_span_end
        expect(described_class.last.time_span_end).not_to eq time_span_end
        expect(described_class.last.status).to eq :noop
      end
    end
  end
end
