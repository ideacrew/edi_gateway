# frozen_string_literal: true

require "rails_helper"

RSpec.describe X12::X220A1::TranslateInbound834, "given an empty string" do
  let(:payload) do
    ""
  end

  subject do
    described_class.new.call(payload)
  end

  it "fails to parse" do
    expect(subject.success?).to be_falsey
    expect(subject.failure).to eq :parse_payload_failed
  end
end

RSpec.describe X12::X220A1::TranslateInbound834, "given invalid xml" do
  let(:payload) do
    "<some namespace> </kjls>"
  end

  subject do
    described_class.new.call(payload)
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

  subject do
    described_class.new.call(payload)
  end

  it "fails to parse" do
    expect(subject.success?).to be_falsey
    expect(subject.failure).not_to eq :parse_payload_failed
  end
end