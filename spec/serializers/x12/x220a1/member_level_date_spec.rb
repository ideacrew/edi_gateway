# frozen_string_literal: true

require "rails_helper"

RSpec.describe X12::X220A1::MemberLevelDate do
  let(:source_xml) do
    <<-XMLCODE
      <DTP_MemberLevelDates_2000 xmlns="urn:x12:schemas:005:010:834A1A1:BenefitEnrollmentAndMaintenance">
        <DTP01__DateTimeQualifier>303</DTP01__DateTimeQualifier>
        <DTP02__DateTimePeriodFormatQualifier>D8</DTP02__DateTimePeriodFormatQualifier>
        <DTP03__StatusInformationEffectiveDate>20200315</DTP03__StatusInformationEffectiveDate>
      </DTP_MemberLevelDates_2000>
    XMLCODE
  end

  subject do
    described_class.parse(source_xml, single: true)
  end

  let(:expected_date) do
    Date.new(
      2020,
      3,
      15
    )
  end

  it "converts to domain parameters" do
    mapped_params = subject.to_domain_parameters
    expect(mapped_params[:date_qualifier]).to eq "303"
    expect(mapped_params[:date]).to eq expected_date
  end
end