# frozen_string_literal: true

require "rails_helper"

RSpec.describe X12::X220A1::TpaOrBroker do
  let(:source_xml) do
    <<-XMLCODE
    <Loop_1000C xmlns="urn:x12:schemas:005:010:834A1A1:BenefitEnrollmentAndMaintenance">
      <N1_TPABrokerName_1000C>
        <N101__EntityIdentifierCode>BO</N101__EntityIdentifierCode>
        <N102__TPAOrBrokerName>A Broker</N102__TPAOrBrokerName>
        <N103__IdentificationCodeQualifier>FI</N103__IdentificationCodeQualifier>
        <N104__TPAOrBrokerIdentificationCode>123456789</N104__TPAOrBrokerIdentificationCode>
      </N1_TPABrokerName_1000C>
    </Loop_1000C>
    XMLCODE
  end

  subject do
    described_class.parse(source_xml, single: true)
  end

  it "has a tpa_or_broker_name" do
    expect(subject.tpa_or_broker_name).to eq "A Broker"
  end

  it "has an identification_code_qualifier" do
    expect(subject.identification_code_qualifier).to eq "FI"
  end

  it "has a tpa_or_broker_identifier" do
    expect(subject.tpa_or_broker_identifier).to eq "123456789"
  end
end