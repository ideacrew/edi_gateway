# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Gdb::Members::RequestSubscriberPolicy, dbclean: :before_each do
  include Dry::Monads[:result, :do]
  describe 'with valid arguments' do

    let(:event) { Success(double) }
    let(:payload) { { subscriber_id: "12345" } }
    let(:obj)  { Gdb::Members::RequestSubscriberPolicy.new }

    context 'fetch subscriber list for the given year' do
      before do
        allow(Gdb::Members::RequestSubscriberPolicy).to receive(:new).and_return(obj)
        allow(obj).to receive(:build_event).and_return(event)
        allow(event.success).to receive(:publish).and_return(true)
        @result = subject.call(payload)
      end

      it 'should return success' do
        expect(@result).to be_success
      end

      it 'should return success with a message' do
        expect(@result.success).to eq("Successfully sent request to subscribe on edi gateway")
      end
    end
  end
end
