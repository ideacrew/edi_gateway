# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Reports::GeneratePreAuditReport, dbclean: :before_each do
  let!(:audit_report_datum) do
    FactoryBot.create(:audit_report_datum, payload: json_payload, hios_id: "12345",
                                           status: "completed", report_type: "pre_audit", year: 2022)
  end
  let(:enrollee_1) do
    {
      enrollee_demographics: demographics,
      first_name: "test",
      middle_name: nil,
      last_name: "test",
      name_sfx: nil,
      hbx_member_id: "12345",
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

  let(:enrollee_2) do
    {
      enrollee_demographics: demographics,
      first_name: "test",
      middle_name: nil,
      last_name: "test",
      name_sfx: nil,
      hbx_member_id: "12345",
      premium_amount: "20.0",
      coverage_start: "2021-11-10",
      coverage_end: "2021-11-10",
      coverage_status: "test",
      relationship_status_code: "life partner",
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
      dob: "2011-10-12",
      ssn: "123456789",
      gender_code: "M",
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
        address_1: "S Street NW",
        address_2: "",
        address_3: "",
        city: "Washington",
        county: "",
        state: "DC",
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

  let!(:policy_params) do
    {
      policy_id: '1001',
      enrollment_group_id: "10010",
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
      aasm_state: "canceled",
      exchange_subscriber_id: "12345",
      effectuation_status: "Y",
      insurance_line_code: "test",
      csr_variant: nil,
      enrollees: [enrollee_1, enrollee_2],
      aptc_maximums: [],
      aptc_credits: []
    }
  end

  let(:json_payload) do
    @result = AcaEntities::Contracts::Policies::PolicyContract.new.call(policy_params)
    [@result.to_h].to_json
  end

  let(:payload_hash) { { payload: { carrier_hios_id: audit_report_datum.hios_id, year: 2022 } } }

  let(:filename) { "#{Rails.root}/carrier_hios_id_#{audit_report_datum.hios_id}_for_year_2022.csv" }

  after :each do
    FileUtils.rm_rf(filename)
  end

  describe "with valid arguments" do
    subject do
      Reports::GeneratePreAuditReport.new.call({ :payload => payload_hash.to_json })
    end

    it "should be success" do
      expect(subject.success?).to eq true
      file_content = CSV.read(filename, col_sep: "|", headers: false)
      expect(file_content.count).to eq 2
      expect(file_content[0]).to include(enrollee_1[:first_name])
      expect(file_content[0]).to include(enrollee_1[:last_name])
      expect(file_content[0]).to include("3")
      expect(file_content[1]).to include("3")
      expect(file_content[0]).to include("1:18")
      expect(file_content[1]).to include("8:53")
    end
  end
end
