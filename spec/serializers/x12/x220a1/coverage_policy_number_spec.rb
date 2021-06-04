# frozen_string_literal: true

require "rails_helper"

RSpec.describe X12::X220A1::CoveragePolicyNumber do
  let(:source_xml) do
    <<-XMLCODE
      <REF_HealthCoveragePolicyNumber_2300 xmlns="urn:x12:schemas:005:010:834A1A1:BenefitEnrollmentAndMaintenance">
        <REF01__ReferenceIdentificationQualifier>CE</REF01__ReferenceIdentificationQualifier>
        <REF02__MemberGroupOrPolicyNumber>A HIOS ID</REF02__MemberGroupOrPolicyNumber>
      </REF_HealthCoveragePolicyNumber_2300>
    XMLCODE
  end

  subject do
    described_class.parse(source_xml, single: true)
  end

  it "converts to domain parameters" do
    mapped_params = subject.to_domain_parameters
    expect(mapped_params[:reference_identification_qualfier]).to eq "CE"
    expect(mapped_params[:reference_identification]).to eq "A HIOS ID"
  end
end