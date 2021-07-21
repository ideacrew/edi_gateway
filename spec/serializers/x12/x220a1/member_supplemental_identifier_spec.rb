# frozen_string_literal: true

require "rails_helper"

RSpec.describe X12::X220A1::MemberSupplementalIdentifier do
  let(:source_xml) do
    <<-XMLCODE
      <REF_MemberSupplementalIdentifier_2000 xmlns="urn:x12:schemas:005:010:834A1A1:BenefitEnrollmentAndMaintenance">
        <REF01__ReferenceIdentificationQualifier>17</REF01__ReferenceIdentificationQualifier>
        <REF02__MemberSupplementalIdentifier>SUPPLEMENTAL_ID_1</REF02__MemberSupplementalIdentifier>
      </REF_MemberSupplementalIdentifier_2000>
    XMLCODE
  end

  subject do
    described_class.parse(source_xml, single: true)
  end

  it "converts to domain parameters" do
    mapped_params = subject.to_domain_parameters
    expect(mapped_params[:reference_identification_qualifier]).to eq "17"
    expect(mapped_params[:reference_identification]).to eq "SUPPLEMENTAL_ID_1"
  end
end