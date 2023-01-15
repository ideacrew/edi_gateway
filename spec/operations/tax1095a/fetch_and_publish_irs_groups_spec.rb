# frozen_string_literal: true

require 'shared_examples/assisted_policy/one_enrolled_member'

RSpec.describe ::Tax1095a::FetchAndPublishIrsGroups do
  include_context 'one_enrolled_member'
  subject { described_class.new }

  describe 'with valid params' do
    before :each do
      @valid_result = subject.call({ tax_year: start_on.year, tax_form_type: "IVL_TAX" })
    end

    it 'should publish the event' do
      expect(@valid_result.success?).to be_truthy
    end
  end

  describe 'with invalid params' do
    before :each do
      @invalid_result = subject.call({ tax_year: start_on.year, tax_form_type: "" })
    end

    it 'should return failure' do
      expect(@invalid_result.failure?).to be_truthy
    end
  end
end
