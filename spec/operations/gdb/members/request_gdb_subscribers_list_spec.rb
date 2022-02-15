# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Gdb::Members::RequestGdbSubscribersList, dbclean: :before_each do
  include Dry::Monads[:result, :do]
  describe 'with valid arguments' do

    let(:event) { Success(double) }
    let(:response) { double("Response", status: 200, body: ["12345"])}
    let(:obj)  { Gdb::Members::RequestGdbSubscribersList.new }

    context 'fetch subscriber list for the given year' do
      before do
        allow(Gdb::Members::RequestGdbSubscribersList).to receive(:new).and_return(obj)
        allow(obj).to receive(:build_event).and_return(event)
        allow(event.success).to receive(:publish).and_return(response)
        @result = subject.call
      end

      it 'should return success with valid glue response' do
        expect(@result).to be_success
      end
    end
  end
end
