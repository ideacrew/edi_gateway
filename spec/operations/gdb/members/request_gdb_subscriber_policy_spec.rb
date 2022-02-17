# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Gdb::Members::RequestGdbSubscriberPolicy do
  include Dry::Monads[:result, :do]
  describe 'with valid arguments' do

    let(:event) { Success(double) }
    let(:response) { double("Response", status: 200, body: ["12345"])}
    let(:payload) { { user_token: "123", subscriber_id: "12345", year: "2022" } }
    let(:obj)  { Gdb::Members::RequestGdbSubscriberPolicy.new }

    context 'fetch subscriber list for the given year' do
      before do
        allow(Gdb::Members::RequestGdbSubscriberPolicy).to receive(:new).and_return(obj)
        allow(obj).to receive(:build_event).and_return(event)
        allow(event.success).to receive(:publish).and_return(response)
        @result = subject.call(payload)
      end

      it 'should return success with valid glue response' do
        expect(@result).to be_success
      end

      it 'should create audit datum record and store payload' do
        expect(AuditReportDatum.count).to eq 1
        expect(AuditReportDatum.all.first.payload).to be_present
      end
    end
  end
end
