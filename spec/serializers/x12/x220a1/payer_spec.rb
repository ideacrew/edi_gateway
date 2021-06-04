# frozen_string_literal: true

require "rails_helper"

RSpec.describe X12::X220A1::Payer do
  let(:source_xml) do
    <<-XMLCODE
    <Loop_1000B xmlns="urn:x12:schemas:005:010:834A1A1:BenefitEnrollmentAndMaintenance">
      <N1_Payer_1000B>
        <N101__EntityIdentifierCode>IN</N101__EntityIdentifierCode>
        <N102__InsurerName>A Carrier</N102__InsurerName>
        <N103__IdentificationCodeQualifier>FI</N103__IdentificationCodeQualifier>
        <N104__InsurerIdentificationCode>123456789</N104__InsurerIdentificationCode>
      </N1_Payer_1000B>
    </Loop_1000B>
    XMLCODE
  end

  subject do
    described_class.parse(source_xml, single: true)
  end

  it "has a insurer_name" do
    expect(subject.insurer_name).to eq "A Carrier"
  end

  it "has an identification_code_qualifier" do
    expect(subject.identification_code_qualifier).to eq "FI"
  end

  it "has a insurer_identifier" do
    expect(subject.insurer_identifier).to eq "123456789"
  end

  it "converts to domain model parameters" do
    mapped_params = subject.to_domain_parameters
    expect(mapped_params[:name]).to eq "A Carrier"
    expect(mapped_params[:identification_code_qualifier]).to eq "FI"
    expect(mapped_params[:identification_code]).to eq "123456789"
  end
end