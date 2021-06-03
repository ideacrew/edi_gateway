# frozen_string_literal: true

require "rails_helper"

RSpec.describe X12::X220A1::Sponsor do
  let(:source_xml) do
    <<-XMLCODE
    <Loop_1000A xmlns="urn:x12:schemas:005:010:834A1A1:BenefitEnrollmentAndMaintenance">
      <N1_SponsorName_1000A>
        <N101__EntityIdentifierCode>P5</N101__EntityIdentifierCode>
        <N102__PlanSponsorName>A Carrier</N102__PlanSponsorName>
        <N103__IdentificationCodeQualifier>FI</N103__IdentificationCodeQualifier>
        <N104__SponsorIdentifier>123456789</N104__SponsorIdentifier>
      </N1_SponsorName_1000A>
    </Loop_1000A>
    XMLCODE
  end

  subject do
    described_class.parse(source_xml, single: true)
  end

  it "has a plan_sponsor_name" do
    expect(subject.plan_sponsor_name).to eq "A Carrier"
  end

  it "has an identification_code_qualifier" do
    expect(subject.identification_code_qualifier).to eq "FI"
  end

  it "has a sponsor_identifier" do
    expect(subject.sponsor_identifier).to eq "123456789"
  end
end