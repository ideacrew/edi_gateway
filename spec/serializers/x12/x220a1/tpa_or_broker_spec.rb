# frozen_string_literal: true

require "rails_helper"

RSpec.describe X12::X220A1::TpaOrBroker, "given a broker loop" do
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

  it "has an entity identifier code" do
    expect(subject.entity_identifier_code).to eq "BO"
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

  it "maps parameters to broker" do
    mapped_params = subject.to_domain_parameters[:broker]
    expect(mapped_params[:name]).to eq "A Broker"
    expect(mapped_params[:identification_code_qualifier]).to eq "FI"
    expect(mapped_params[:identification_code]).to eq "123456789"
  end
end

RSpec.describe X12::X220A1::TpaOrBroker, "given a tpa loop" do
  let(:source_xml) do
    <<-XMLCODE
    <Loop_1000C xmlns="urn:x12:schemas:005:010:834A1A1:BenefitEnrollmentAndMaintenance">
      <N1_TPABrokerName_1000C>
        <N101__EntityIdentifierCode>TV</N101__EntityIdentifierCode>
        <N102__TPAOrBrokerName>A TPA</N102__TPAOrBrokerName>
        <N103__IdentificationCodeQualifier>FI</N103__IdentificationCodeQualifier>
        <N104__TPAOrBrokerIdentificationCode>123456789</N104__TPAOrBrokerIdentificationCode>
      </N1_TPABrokerName_1000C>
    </Loop_1000C>
    XMLCODE
  end

  subject do
    described_class.parse(source_xml, single: true)
  end

  it "maps parameters to third_party_administrator" do
    mapped_params = subject.to_domain_parameters[:third_party_administrator]
    expect(mapped_params[:name]).to eq "A TPA"
    expect(mapped_params[:identification_code_qualifier]).to eq "FI"
    expect(mapped_params[:identification_code]).to eq "123456789"
  end
end