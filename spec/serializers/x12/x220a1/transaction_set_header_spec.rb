# frozen_string_literal: true

require "rails_helper"

RSpec.describe X12::X220A1::TransactionSetHeader do
  let(:source_xml) do
    <<-XMLCODE
    <ST_TransactionSetHeader xmlns="urn:x12:schemas:005:010:834A1A1:BenefitEnrollmentAndMaintenance">
      <ST01__TransactionSetIdentifierCode>834</ST01__TransactionSetIdentifierCode>
      <ST02__TransactionSetControlNumber>12345</ST02__TransactionSetControlNumber>
      <ST03__ImplementationConventionReference>X220A1</ST03__ImplementationConventionReference>
    </ST_TransactionSetHeader>
    XMLCODE
  end

  subject do
    described_class.parse(source_xml, single: true)
  end

  it "has a transaction_set_identifier_code" do
    expect(subject.transaction_set_identifier_code).to eq "834"
  end

  it "has a transaction_set_control_number" do
    expect(subject.transaction_set_control_number).to eq "12345"
  end

  it "has an implementation_convention_reference" do
    expect(subject.implementation_convention_reference).to eq "X220A1"
  end
end