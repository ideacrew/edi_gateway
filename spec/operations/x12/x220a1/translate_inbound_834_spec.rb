# frozen_string_literal: true

require "rails_helper"

RSpec.describe X12::X220A1::TranslateInbound834, "given an empty string" do
  let(:envelope) do
    {}
  end

  let(:payload) do
    ""
  end

  subject do
    described_class.new.call({
                               payload: payload,
                               envelope: envelope
                             })
  end

  it "fails to parse" do
    expect(subject.success?).to be_falsey
    expect(subject.failure).to eq :parse_payload_failed
  end
end

RSpec.describe X12::X220A1::TranslateInbound834, "given invalid xml" do
  let(:envelope) do
    {}
  end

  let(:payload) do
    "<some namespace> </kjls>"
  end

  subject do
    described_class.new.call({
                               payload: payload,
                               envelope: envelope
                             })
  end

  it "fails to parse" do
    expect(subject.success?).to be_falsey
    expect(subject.failure).to eq :parse_payload_failed
  end
end

RSpec.describe X12::X220A1::TranslateInbound834, "given:
  - syntactically valid XML
  - that doesn't have the required attributes
" do
  let(:payload) do
    <<-XMLCODE
    <X12_005010X220A1_834A1 xmlns="urn:x12:schemas:005:010:834A1A1:BenefitEnrollmentAndMaintenance">
      <ST_TransactionSetHeader>
      </ST_TransactionSetHeader>
      <BGN_BeginningSegment>
      </BGN_BeginningSegment>
      <Loop_1000A>
      </Loop_1000A>
      <Loop_1000B>
      </Loop_1000B>
      <Loop_1000C>
      </Loop_1000C>
      <Loop_2000>
      </Loop_2000>
    </X12_005010X220A1_834A1>
    XMLCODE
  end

  let(:envelope) do
    {}
  end

  subject do
    described_class.new.call({
                               payload: payload,
                               envelope: envelope
                             })
  end

  it "fails to validate" do
    expect(subject.success?).to be_falsey
    expect(subject.failure).not_to eq :parse_payload_failed
  end
end

RSpec.describe X12::X220A1::TranslateInbound834, "given headers and a full XML with almost everything" do
  let(:headers) do
    {
      interchange_control_number: "12345",
      interchange_sender_qualifier: "FI",
      interchange_sender_id: "543219",
      interchange_receiver_qualifier: "FI",
      interchange_receiver_id: "543217",
      interchange_timestamp: DateTime.now,
      group_control_number: "123456",
      application_senders_code: "ME0",
      application_receivers_code: "SHP",
      group_creation_timestamp: DateTime.now,
      b2b_message_id: "1234",
      b2b_created_at: DateTime.now,
      b2b_updated_at: DateTime.now,
      b2b_business_message_id: "4321",
      b2b_protocol_message_id: "54321",
      b2b_in_trading_partner: "ME0",
      b2b_out_trading_partner: "CF",
      b2b_message_status: "MSG_ERROR",
      b2b_direction: "INBOUND",
      b2b_document_type_name: "834",
      b2b_document_protocol_name: "X12",
      b2b_document_protocol_version: "X220A1",
      b2b_document_definition: "834Def"
    }
  end

  let(:payload) do
    <<-XMLCODE
    <X12_005010X220A1_834A1 xmlns="urn:x12:schemas:005:010:834A1A1:BenefitEnrollmentAndMaintenance">
      <ST_TransactionSetHeader>
        <ST01__TransactionSetIdentifierCode>834</ST01__TransactionSetIdentifierCode>
        <ST02__TransactionSetControlNumber>12345</ST02__TransactionSetControlNumber>
        <ST03__ImplementationConventionReference>X220A1</ST03__ImplementationConventionReference>
      </ST_TransactionSetHeader>
      <BGN_BeginningSegment>
        <BGN01__TransactionSetPurposeCode>00</BGN01__TransactionSetPurposeCode>
        <BGN02__TransactionSetReferenceNumber>12345</BGN02__TransactionSetReferenceNumber>
        <BGN03__TransactionSetCreationDate>20200115</BGN03__TransactionSetCreationDate>
        <BGN04__TransactionSetCreationTime>18201032</BGN04__TransactionSetCreationTime>
        <BGN05__TimeZoneCode>UT</BGN05__TimeZoneCode>
        <!-- Optional -->
        <BGN06__OriginalTransactionSetReferenceNumber>3210</BGN06__OriginalTransactionSetReferenceNumber>
        <BGN08__ActionCode>2</BGN08__ActionCode>
      </BGN_BeginningSegment>
      <Loop_1000A>
        <N1_SponsorName_1000A>
          <N101__EntityIdentifierCode>P5</N101__EntityIdentifierCode>
          <N102__PlanSponsorName>An Employer or Exchange</N102__PlanSponsorName>
          <N103__IdentificationCodeQualifier>FI</N103__IdentificationCodeQualifier>
          <N104__SponsorIdentifier>123456789</N104__SponsorIdentifier>
        </N1_SponsorName_1000A>
      </Loop_1000A>
      <Loop_1000B>
        <N1_Payer_1000B>
          <N101__EntityIdentifierCode>IN</N101__EntityIdentifierCode>
          <N102__InsurerName>A Carrier</N102__InsurerName>
          <N103__IdentificationCodeQualifier>FI</N103__IdentificationCodeQualifier>
          <N104__InsurerIdentificationCode>123456789</N104__InsurerIdentificationCode>
        </N1_Payer_1000B>
      </Loop_1000B>
      <Loop_1000C>
        <N1_TPABrokerName_1000C>
          <N101__EntityIdentifierCode>BO</N101__EntityIdentifierCode>
          <N102__TPAOrBrokerName>A Broker</N102__TPAOrBrokerName>
          <N103__IdentificationCodeQualifier>FI</N103__IdentificationCodeQualifier>
          <N104__TPAOrBrokerIdentificationCode>123456789</N104__TPAOrBrokerIdentificationCode>
        </N1_TPABrokerName_1000C>
      </Loop_1000C>
      <Loop_1000C>
        <N1_TPABrokerName_1000C>
          <N101__EntityIdentifierCode>TV</N101__EntityIdentifierCode>
          <N102__TPAOrBrokerName>A TPA</N102__TPAOrBrokerName>
          <N103__IdentificationCodeQualifier>FI</N103__IdentificationCodeQualifier>
          <N104__TPAOrBrokerIdentificationCode>123456789</N104__TPAOrBrokerIdentificationCode>
        </N1_TPABrokerName_1000C>
      </Loop_1000C>
      <Loop_2000>
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

    </Loop_2000>
    </X12_005010X220A1_834A1>
    XMLCODE
  end

  let(:envelope) do
    Inbound834::ExtractGatewayEnvelope.new.call(
      headers
    ).value!
  end

  subject do
    described_class.new.call({
                               payload: payload,
                               envelope: envelope
                             })
  end

  it "succeeds" do
    expect(subject.success?).to be_truthy
  end
end