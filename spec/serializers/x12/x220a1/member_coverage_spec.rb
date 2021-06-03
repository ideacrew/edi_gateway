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
      <DTP_HealthCoverageDates_2300>
        <DTP01__DateTimeQualifier>303</DTP01__DateTimeQualifier>
        <DTP02__DateTimePeriodFormatQualifier>D8</DTP02__DateTimePeriodFormatQualifier>
        <DTP03__CoveragePeriod>20200401</DTP03__CoveragePeriod>
      </DTP_HealthCoverageDates_2300>
      <DTP_HealthCoverageDates_2300>
        <DTP01__DateTimeQualifier>695</DTP01__DateTimeQualifier>
        <DTP02__DateTimePeriodFormatQualifier>RD8</DTP02__DateTimePeriodFormatQualifier>
        <DTP03__CoveragePeriod>20200101-20200331</DTP03__CoveragePeriod>
      </DTP_HealthCoverageDates_2300>
      <REF_HealthCoveragePolicyNumber_2300>
        <REF01__ReferenceIdentificationQualifier>CE</REF01__ReferenceIdentificationQualifier>
        <REF02__MemberGroupOrPolicyNumber>A HIOS ID</REF02__MemberGroupOrPolicyNumber>
      </REF_HealthCoveragePolicyNumber_2300>
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

  it "has coverage_policy_numbers" do
    expect(subject.coverage_policy_numbers.length).to eq 1
    first_policy_number = subject.coverage_policy_numbers.first
    expect(first_policy_number.identification_qualifier).to eq "CE"
    expect(first_policy_number.reference_identification).to eq "A HIOS ID"
  end

  it "has coverage_dates" do
    expect(subject.coverage_dates.length).to eq 2
    expect(
      subject.coverage_dates.first.date_qualifier
    ).to eq "303"
    expect(
      subject.coverage_dates.first.format_qualifier
    ).to eq "D8"
    expect(
      subject.coverage_dates.first.date
    ).to eq "20200401"
    expect(
      subject.coverage_dates.last.date_qualifier
    ).to eq "695"
    expect(
      subject.coverage_dates.last.format_qualifier
    ).to eq "RD8"
    expect(
      subject.coverage_dates.last.date
    ).to eq "20200101-20200331"
  end
end