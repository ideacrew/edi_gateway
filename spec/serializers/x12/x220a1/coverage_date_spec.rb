# frozen_string_literal: true

require "rails_helper"

RSpec.describe X12::X220A1::CoverageDate, "when a date" do
  let(:source_xml) do
    <<-XMLCODE
      <DTP_HealthCoverageDates_2300 xmlns="urn:x12:schemas:005:010:834A1A1:BenefitEnrollmentAndMaintenance">
        <DTP01__DateTimeQualifier>303</DTP01__DateTimeQualifier>
        <DTP02__DateTimePeriodFormatQualifier>D8</DTP02__DateTimePeriodFormatQualifier>
        <DTP03__CoveragePeriod>20200401</DTP03__CoveragePeriod>
      </DTP_HealthCoverageDates_2300>
    XMLCODE
  end

  subject do
    described_class.parse(source_xml, single: true)
  end

  let(:expected_date) do
    Date.new(
      2020,
      4,
      1
    )
  end

  it "converts to domain parameters" do
    mapped_params = subject.to_domain_parameters
    expect(mapped_params[:date_qualifier]).to eq "303"
    expect(mapped_params[:date]).to eq expected_date
  end
end

RSpec.describe X12::X220A1::CoverageDate, "when a range" do
  let(:source_xml) do
    <<-XMLCODE
      <DTP_HealthCoverageDates_2300 xmlns="urn:x12:schemas:005:010:834A1A1:BenefitEnrollmentAndMaintenance">
        <DTP01__DateTimeQualifier>695</DTP01__DateTimeQualifier>
        <DTP02__DateTimePeriodFormatQualifier>RD8</DTP02__DateTimePeriodFormatQualifier>
        <DTP03__CoveragePeriod>20200101-20200331</DTP03__CoveragePeriod>
      </DTP_HealthCoverageDates_2300>
    XMLCODE
  end

  subject do
    described_class.parse(source_xml, single: true)
  end

  let(:expected_start_date) do
    Date.new(
      2020,
      1,
      1
    )
  end

  let(:expected_end_date) do
    Date.new(
      2020,
      3,
      31
    )
  end

  it "converts to domain parameters" do
    mapped_params = subject.to_domain_parameters
    expect(mapped_params[:start_date]).to eq expected_start_date
    expect(mapped_params[:end_date]).to eq expected_end_date
  end
end