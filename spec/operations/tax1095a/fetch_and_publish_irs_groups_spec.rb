# frozen_string_literal: true

require 'shared_examples/assisted_policy/one_enrolled_member'

RSpec.describe ::Tax1095a::FetchAndPublishIrsGroups do
  include_context 'one_enrolled_member'
  subject { described_class.new }

  describe 'with valid params' do
    before :each do
      insurance_policy_1.insurance_product.update_attributes(metal_level: "catastrophic")
      @valid_result = subject.call({ tax_year: start_on.year, tax_form_type: "IVL_CAP", exclusion_list: [],
                                     transmission_kind: "1095a" })
    end

    it 'should publish the event' do
      expect(@valid_result.success?).to be_truthy
    end
  end

  describe 'with invalid params' do
    before :each do
      @invalid_result = subject.call({ tax_year: start_on.year, tax_form_type: "", exclusion_list: [],
                                       transmission_kind: "1095a" })
    end

    it 'should return failure' do
      expect(@invalid_result.failure?).to be_truthy
    end
  end
end
