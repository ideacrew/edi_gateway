# frozen_string_literal: true

require "rails_helper"

RSpec.describe X12::X220A1::MemberLoop do
  let(:source_xml) do
    <<-XMLCODE
    <Loop_2000 xmlns="urn:x12:schemas:005:010:834A1A1:BenefitEnrollmentAndMaintenance">
      <INS_MemberLevelDetail_2000>
        <INS01__MemberIndicator>Y</INS01__MemberIndicator>
        <INS03__MaintenanceTypeCode>021</INS03__MaintenanceTypeCode>
        <INS04__MaintenanceReasonCode>EC</INS04__MaintenanceReasonCode>
      </INS_MemberLevelDetail_2000>
      <REF_SubscriberIdentifier_2000>
        <REF01__ReferenceIdentificationQualifier>0F</REF01__ReferenceIdentificationQualifier>
        <REF02__SubscriberIdentifier>SUBID</REF02__SubscriberIdentifier>
      </REF_SubscriberIdentifier_2000>
      <REF_MemberSupplementalIdentifier_2000>
        <REF01__ReferenceIdentificationQualifier>17</REF01__ReferenceIdentificationQualifier>
        <REF02__MemberSupplementalIdentifier>SUPPLEMENTAL_ID_1</REF02__MemberSupplementalIdentifier>
      </REF_MemberSupplementalIdentifier_2000>
      <REF_MemberSupplementalIdentifier_2000>
        <REF01__ReferenceIdentificationQualifier>ZZ</REF01__ReferenceIdentificationQualifier>
        <REF02__MemberSupplementalIdentifier>SUPPLEMENTAL_ID_2</REF02__MemberSupplementalIdentifier>
      </REF_MemberSupplementalIdentifier_2000>
      <DTP_MemberLevelDates_2000>
        <DTP01__DateTimeQualifier>303</DTP01__DateTimeQualifier>
        <DTP02__DateTimePeriodFormatQualifier>D8</DTP02__DateTimePeriodFormatQualifier>
        <DTP03__StatusInformationEffectiveDate>20200315</DTP03__StatusInformationEffectiveDate>
      </DTP_MemberLevelDates_2000>
      <Loop_2300>
      </Loop_2300>
      <Loop_2300>
      </Loop_2300>
    </Loop_2000>
    XMLCODE
  end

  subject do
    described_class.parse(source_xml, single: true)
  end

  it "has a subscriber_indicator" do
    expect(subject.subscriber_indicator).to eq true
  end

  it "has a maintenance_type_code" do
    expect(subject.maintenance_type_code).to eq "021"
  end

  it "has a maintenance_reason_code" do
    expect(subject.maintenance_reason_code).to eq "EC"
  end

  it "has a subscriber_identifier" do
    expect(subject.subscriber_identifier).to eq "SUBID"
  end

  it "has member supplemental identifiers" do
    expect(subject.member_supplemental_identifiers.length).to eq 2
    expect(
      subject.member_supplemental_identifiers.last.identification_qualifier
    ).to eq "ZZ"
    expect(
      subject.member_supplemental_identifiers.first.identification_qualifier
    ).to eq "17"

    expect(
      subject.member_supplemental_identifiers.last.supplemental_identifier
    ).to eq "SUPPLEMENTAL_ID_2"
    expect(
      subject.member_supplemental_identifiers.first.supplemental_identifier
    ).to eq "SUPPLEMENTAL_ID_1"
  end

  it "has member_level_dates" do
    expect(subject.member_level_dates.length).to eq 1
    member_date = subject.member_level_dates.first
    expect(member_date.date_qualifier).to eq "303"
    expect(member_date.format_qualifier).to eq "D8"
    expect(member_date.date).to eq "20200315"
  end

  it "has member_coverage" do
    expect(subject.member_coverage.length).to eq 2
  end
end