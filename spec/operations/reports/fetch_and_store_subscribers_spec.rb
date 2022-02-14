# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

RSpec.describe Reports::FetchSubscribers, dbclean: :before_each do
  include Dry::Monads[:result, :do]
  describe 'with valid arguments' do

    let(:event) { Success(double) }
    let(:obj)  {Reports::FetchSubscribers.new}


    context 'fetch subscriber list and store coverage information of each subscriber' do
        before do
          # allow(Reports::FetchSubscribers).to receive(:new).and_return(obj)
          # allow(obj).to receive(:build_event).and_return(event)
          # allow(event.success).to receive(:publish).and_return(true)
          @result = subject.call
        end

      it 'should return success with valid mitc response' do
        expect(@result).to be_success
      end

      it 'should return success with a message' do
        expect(@result.success).to eq("Successfully sent request payload to Glue")
      end
    end
  end
end