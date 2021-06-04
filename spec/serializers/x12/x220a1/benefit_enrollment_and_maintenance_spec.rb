# frozen_string_literal: true

require "rails_helper"

RSpec.describe X12::X220A1::BenefitEnrollmentAndMaintenance do
  let(:source_xml) do
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
      <Loop_1000C>
        <N1_TPABrokerName_1000C>
          <N101__EntityIdentifierCode>TV</N101__EntityIdentifierCode>
        </N1_TPABrokerName_1000C>
      </Loop_1000C>
      <Loop_2000>
      </Loop_2000>
    </X12_005010X220A1_834A1>
    XMLCODE
  end

  subject do
    X12::X220A1::BenefitEnrollmentAndMaintenance.parse(source_xml, single: true)
  end

  it "has a sponsor loop" do
    expect(subject.sponsor).not_to be_nil
  end

  it "has a payer loop" do
    expect(subject.payer).not_to be_nil
  end

  it "has a tpa_or_broker loop" do
    expect(subject.tpa_or_broker).not_to be_nil
  end

  it "has a member loop" do
    expect(subject.member_loops.length).to eq 1
  end

  it "has a transaction_set_header" do
    expect(subject.transaction_set_header).not_to be_nil
  end

  it "has a beginning_segment" do
    expect(subject.beginning_segment).not_to be_nil
  end

  it "converts its children to mapped domain values" do
    mapped_params = subject.to_domain_parameters
    expect(mapped_params[:sponsor]).not_to be_nil
    expect(mapped_params[:payer]).not_to be_nil
    expect(mapped_params[:broker]).not_to be_nil
    expect(mapped_params[:third_party_administrator]).not_to be_nil
    expect(mapped_params[:members].length).to eq 1
  end
end