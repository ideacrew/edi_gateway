# frozen_string_literal: true

RSpec.describe ::Tax1095a::PublishRequest do
  subject { described_class.new }

  context 'with valid params' do
    before :each do
      @valid_result = subject.call({ payload: { tax_year: 2023, tax_form_type: "IVL_TAX", irs_group_id: "123456" },
                                     event_name: "insurance_policies.tax1095a_payload.requested" })
    end

    it 'should publish the event' do
      expect(@valid_result.success?).to be_truthy
    end
  end

  context 'with invalid params' do
    before :each do
      @invalid_result = subject.call({ payload: { tax_year: 2023, tax_form_type: "IVL_TAX", irs_group_id: "123456" },
                                       event_name: "" })
    end

    it 'should return failure' do
      expect(@invalid_result.failure?).to be_truthy
    end
  end
end
