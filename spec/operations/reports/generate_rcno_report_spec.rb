# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

RSpec.describe Reports::GenerateRcnoReport do
  include Dry::Monads[:result, :do]

  let!(:audit_report_datum) do
    FactoryBot.create(:audit_report_datum, payload: json_payload, hios_id: "33653", year: 2022,
                                           subscriber_id: "1234567", status: "completed", report_type: "pre_audit")
  end
  let(:enrollee) do
    {
      enrollee_demographics: demographics,
      first_name: "dummy",
      middle_name: nil,
      last_name: "dummy|test",
      name_sfx: nil,
      hbx_member_id: "1234567",
      premium_amount: "20.0",
      coverage_start: "2021-11-10",
      coverage_end: "2021-11-10",
      coverage_status: "test",
      relationship_status_code: "self",
      issuer_assigned_member_id: "12345",
      issuer_assigned_policy_id: nil,
      is_subscriber: "true",
      is_responsible_party: "false",
      addresses: addresses,
      phones: phones,
      emails: emails,
      segments: segments
    }
  end

  let(:demographics) do
    {
      dob: "2020-01-01",
      ssn: "999999999",
      gender_code: "F",
      tobacco_use_code: "unknown"
    }
  end

  let(:segments) do
    [
      {
        id: "1100500-45009-1100500-20220101-20221231",
        effective_start_date: "2021-10-12",
        effective_end_date: "2021-10-12",
        individual_premium_amount: "21.0",
        individual_responsible_amount: nil,
        total_premium_amount: "32.0",
        total_responsible_amount: "32.0",
        aptc_amount: "23.1",
        csr_variant: "0"
      }
    ]
  end

  let(:addresses) do
    [
      {
        kind: "home",
        address_1: "dummy",
        address_2: "",
        address_3: "",
        city: "dummy",
        county: "",
        state: "ME",
        location_state_code: nil,
        full_text: nil,
        zip: "20009",
        country_name: ""
      }
    ]
  end

  let(:phones) do
    [
      {
        kind: "home",
        country_code: "",
        area_code: "202",
        number: "2991290",
        extension: "",
        primary: true,
        full_phone_number: "2022991290"
      }
    ]
  end

  let(:emails) do
    [
      {
        kind: "home",
        address: "test@gmail.com"
      }
    ]
  end

  let!(:policy1_params) do
    {
      policy_id: '1001',
      enrollment_group_id: "1234567",
      hios_plan_id: '1001',
      qhp_id: '1001',
      allocated_aptc: "20.0",
      elected_aptc: "20.0",
      applied_aptc: "20.0",
      csr_amt: nil,
      total_premium_amount: "20.0",
      total_responsible_amount: "20.0",
      coverage_kind: "health",
      term_for_np: "false",
      rating_area: "RDC",
      service_area: nil,
      last_maintenance_date: "2021-11-10",
      last_maintenance_time: "16:40:41",
      aasm_state: "submitted",
      exchange_subscriber_id: "12345",
      effectuation_status: "Y",
      insurance_line_code: "test",
      csr_variant: nil,
      enrollees: [enrollee],
      aptc_maximums: [],
      aptc_credits: []
    }
  end

  let!(:policy2_params) do
    {
      policy_id: '1001',
      enrollment_group_id: "10011",
      hios_plan_id: '1001',
      qhp_id: '1001',
      allocated_aptc: "20.0",
      elected_aptc: "20.0",
      applied_aptc: "20.0",
      csr_amt: nil,
      total_premium_amount: "20.0",
      total_responsible_amount: "20.0",
      coverage_kind: "health",
      term_for_np: "false",
      rating_area: "RDC",
      service_area: nil,
      last_maintenance_date: "2021-11-10",
      last_maintenance_time: "16:40:41",
      aasm_state: "submitted",
      exchange_subscriber_id: "12345",
      effectuation_status: "Y",
      insurance_line_code: "test",
      csr_variant: nil,
      enrollees: [enrollee],
      aptc_maximums: [],
      aptc_credits: []
    }
  end

  let(:json_payload) do
    result_1 = AcaEntities::Contracts::Policies::PolicyContract.new.call(policy1_params)
    result_2 = AcaEntities::Contracts::Policies::PolicyContract.new.call(policy2_params)
    [result_1.to_h, result_2.to_h].to_json
  end

  after :each do
    FileUtils.rm_rf("#{Rails.root}/rcno_carrier_hios_id_#{audit_report_datum.hios_id}_for_year_2022.csv")
  end

  describe "with valid arguments" do
    before do
      policies = JSON.parse(audit_report_datum.payload)
      policies.each do |policy|
        audit_report_datum.ard_policies << Policy.new(payload: policy.to_json, policy_eg_id: policy["enrollment_group_id"])
      end
    end

    let(:output_file) { "#{Rails.root}/rcno_carrier_hios_id_#{audit_report_datum&.hios_id}_for_year_2022.csv" }

    it "should be success" do
      subject = described_class.new
      payload_hash = { payload: { carrier_hios_id: audit_report_datum&.hios_id, year: 2022 } }
      result = subject.call({ :payload => payload_hash.to_json })
      expect(result.success?).to eq true
      expect(File.exist?(output_file)).to eq true
      file_content = CSV.read(output_file, col_sep: "|", headers: false)
      expect(file_content.count).to eq 3
      expect(file_content[1]).to include("10011")
      expect(file_content[1]).to include("dummytest")
    end
  end
end
