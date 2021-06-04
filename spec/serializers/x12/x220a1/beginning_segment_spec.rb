# frozen_string_literal: true

require "rails_helper"

RSpec.describe X12::X220A1::BeginningSegment do
  let(:source_xml) do
    <<-XMLCODE
    <BGN_BeginningSegment xmlns="urn:x12:schemas:005:010:834A1A1:BenefitEnrollmentAndMaintenance">
      <BGN01__TransactionSetPurposeCode>00</BGN01__TransactionSetPurposeCode>
      <BGN02__TransactionSetReferenceNumber>12345</BGN02__TransactionSetReferenceNumber>
      <BGN03__TransactionSetCreationDate>20200115</BGN03__TransactionSetCreationDate>
      <BGN04__TransactionSetCreationTime>18201032</BGN04__TransactionSetCreationTime>
      <BGN05__TimeZoneCode>UT</BGN05__TimeZoneCode>
      <!-- Optional -->
      <BGN06__OriginalTransactionSetReferenceNumber>3210</BGN06__OriginalTransactionSetReferenceNumber>
      <BGN08__ActionCode>02</BGN08__ActionCode>
    </BGN_BeginningSegment>
    XMLCODE
  end

  let(:expected_timestamp) do
    DateTime.new(
      2020,
      1,
      15,
      18,
      20,
      10.32
    )
  end

  subject do
    described_class.parse(source_xml, single: true)
  end

  it "has a transaction set purpose code" do
    expect(subject.transaction_set_purpose_code).to eq "00"
  end

  it "has a transaction set reference number" do
    expect(subject.transaction_set_reference_number).to eq "12345"
  end

  it "has an action code" do
    expect(subject.action_code).to eq "02"
  end

  it "has a transaction_set_creation_date" do
    expect(subject.transaction_set_creation_date).to eq "20200115"
  end

  it "has a transaction_set_creation_time" do
    expect(subject.transaction_set_creation_time).to eq "18201032"
  end

  it "has a time zone code" do
    expect(subject.time_zone_code).to eq "UT"
  end

  it "converts to domain model parameters" do
    mapped_params = subject.to_domain_parameters
    expect(mapped_params[:transaction_set_purpose_code]).to eq "00"
    expect(mapped_params[:transaction_set_reference_number]).to eq "12345"
    expect(mapped_params[:action_code]).to eq "02"
    expect(mapped_params[:reference_identification]).to eq "3210"
    expect(mapped_params[:transaction_set_timestamp]).to eq expected_timestamp
  end
end

RSpec.describe X12::X220A1::BeginningSegment, "given the shortest form time" do
  let(:source_xml) do
    <<-XMLCODE
    <BGN_BeginningSegment xmlns="urn:x12:schemas:005:010:834A1A1:BenefitEnrollmentAndMaintenance">
      <BGN02__TransactionSetReferenceNumber>12345</BGN02__TransactionSetReferenceNumber>
      <BGN03__TransactionSetCreationDate>20200115</BGN03__TransactionSetCreationDate>
      <BGN04__TransactionSetCreationTime>1820</BGN04__TransactionSetCreationTime>
      <BGN05__TimeZoneCode>UT</BGN05__TimeZoneCode>
    </BGN_BeginningSegment>
    XMLCODE
  end

  let(:expected_timestamp) do
    DateTime.new(
      2020,
      1,
      15,
      18,
      20
    )
  end

  subject do
    described_class.parse(source_xml, single: true)
  end

  it "converts to domain model parameters" do
    mapped_params = subject.to_domain_parameters
    expect(mapped_params[:transaction_set_timestamp]).to eq expected_timestamp
  end
end

RSpec.describe X12::X220A1::BeginningSegment, "given time with seconds, in Eastern Time" do
  let(:source_xml) do
    <<-XMLCODE
    <BGN_BeginningSegment xmlns="urn:x12:schemas:005:010:834A1A1:BenefitEnrollmentAndMaintenance">
      <BGN02__TransactionSetReferenceNumber>12345</BGN02__TransactionSetReferenceNumber>
      <BGN03__TransactionSetCreationDate>20200115</BGN03__TransactionSetCreationDate>
      <BGN04__TransactionSetCreationTime>182001</BGN04__TransactionSetCreationTime>
      <BGN05__TimeZoneCode>ET</BGN05__TimeZoneCode>
    </BGN_BeginningSegment>
    XMLCODE
  end

  let(:expected_timestamp) do
    ActiveSupport::TimeZone["Eastern Time (US & Canada)"].local(
      2020,
      1,
      15,
      18,
      20,
      1
    ).to_datetime
  end

  subject do
    described_class.parse(source_xml, single: true)
  end

  it "converts to domain model parameters" do
    mapped_params = subject.to_domain_parameters
    expect(mapped_params[:transaction_set_timestamp]).to eq expected_timestamp
  end
end

RSpec.describe X12::X220A1::BeginningSegment, "given time with tenths of a second in Eastern Daylight Time" do
  let(:source_xml) do
    <<-XMLCODE
    <BGN_BeginningSegment xmlns="urn:x12:schemas:005:010:834A1A1:BenefitEnrollmentAndMaintenance">
      <BGN02__TransactionSetReferenceNumber>12345</BGN02__TransactionSetReferenceNumber>
      <BGN03__TransactionSetCreationDate>20200115</BGN03__TransactionSetCreationDate>
      <BGN04__TransactionSetCreationTime>1820012</BGN04__TransactionSetCreationTime>
      <BGN05__TimeZoneCode>ED</BGN05__TimeZoneCode>
    </BGN_BeginningSegment>
    XMLCODE
  end

  let(:expected_timestamp) do
    DateTime.new(
      2020,
      1,
      15,
      18,
      20,
      1.2,
      "-04:00"
    )
  end

  subject do
    described_class.parse(source_xml, single: true)
  end

  it "converts to domain model parameters" do
    mapped_params = subject.to_domain_parameters
    expect(mapped_params[:transaction_set_timestamp]).to eq expected_timestamp
  end
end

RSpec.describe X12::X220A1::BeginningSegment, "given time with hundredths of a second in Eastern Standard Time" do
  let(:source_xml) do
    <<-XMLCODE
    <BGN_BeginningSegment xmlns="urn:x12:schemas:005:010:834A1A1:BenefitEnrollmentAndMaintenance">
      <BGN02__TransactionSetReferenceNumber>12345</BGN02__TransactionSetReferenceNumber>
      <BGN03__TransactionSetCreationDate>20200115</BGN03__TransactionSetCreationDate>
      <BGN04__TransactionSetCreationTime>18200123</BGN04__TransactionSetCreationTime>
      <BGN05__TimeZoneCode>ES</BGN05__TimeZoneCode>
    </BGN_BeginningSegment>
    XMLCODE
  end

  let(:expected_timestamp) do
    DateTime.new(
      2020,
      1,
      15,
      18,
      20,
      1.23,
      "-05:00"
    )
  end

  subject do
    described_class.parse(source_xml, single: true)
  end

  it "converts to domain model parameters" do
    mapped_params = subject.to_domain_parameters
    expect(mapped_params[:transaction_set_timestamp]).to eq expected_timestamp
  end
end