# frozen_string_literal: true

require "rails_helper"

RSpec.describe X12::X220A1::MemberCoverage do
  let(:source_xml) do
    <<-XMLCODE
    <Loop_2300 xmlns="urn:x12:schemas:005:010:834A1A1:BenefitEnrollmentAndMaintenance">
      <HD_HealthCoverage_2300>
        <HD01__MaintenanceTypeCode>021</HD01__MaintenanceTypeCode>
        <HD03__InsuranceLineCode>HLT</HD03__InsuranceLineCode>
        <HD04__PlanCoverageDescription>EMP</HD04__PlanCoverageDescription>
      </HD_HealthCoverage_2300>
    </Loop_2300>
    XMLCODE
  end

  subject do
    described_class.parse(source_xml, single: true)
  end

  it "has a maintenance_type_code" do
    expect(subject.maintenance_type_code).to eq "021"
  end

  it "has a insurance_line_code" do
    expect(subject.insurance_line_code).to eq "HLT"
  end

  it "has a coverage_level_code" do
    expect(subject.coverage_level_code).to eq "EMP"
  end
end